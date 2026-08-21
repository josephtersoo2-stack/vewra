import re
import json
import logging
import requests
from typing import Dict, Any, List
from urllib.parse import urlparse, parse_qs

from apps.ai_service.models import AISettings
from apps.ai_service.providers.gemini import fetch_gemini_models, generate_keywords_gemini
from apps.ai_service.providers.openrouter import fetch_openrouter_models, generate_keywords_openrouter

logger = logging.getLogger(__name__)

YOUTUBE_REGEX = re.compile(
    r'(?:https?:\/\/)?(?:www\.|m\.)?(?:youtube\.com\/(?:watch\?(?:.*&)?v=|embed\/|v\/|shorts\/)|youtu\.be\/)([\w-]{11})',
    re.IGNORECASE
)

def extract_youtube_video_id(url: str) -> str:
    if not url:
        return ""
    url = url.strip()
    match = YOUTUBE_REGEX.search(url)
    if match:
        return match.group(1)
    try:
        parsed = urlparse(url)
        if 'youtube' in parsed.netloc:
            qs = parse_qs(parsed.query)
            if 'v' in qs and qs['v']:
                return qs['v'][0]
    except Exception:
        pass
    if len(url) == 11 and re.match(r'^[\w-]+$', url):
        return url
    return ""


def extract_youtube_metadata(url_or_id: str) -> Dict[str, Any]:
    """
    Fetches real video title, channel name, and thumbnail from YouTube.
    Uses public YouTube oEmbed service and HTML fallback.
    """
    video_id = extract_youtube_video_id(url_or_id)
    if not video_id:
        raise ValueError(f"Invalid YouTube URL or Video ID: '{url_or_id}'")

    meta = {
        'video_id': video_id,
        'title': '',
        'channel': '',
        'author_name': '',
        'thumbnail_url': f"https://img.youtube.com/vi/{video_id}/hqdefault.jpg",
        'description': '',
    }

    # 1. Try YouTube oEmbed API (Fast & Reliable, No API Key needed)
    try:
        oembed_url = f"https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v={video_id}&format=json"
        res = requests.get(oembed_url, timeout=6)
        if res.status_code == 200:
            data = res.json()
            meta['title'] = data.get('title', '').strip()
            meta['channel'] = data.get('author_name', '').strip()
            meta['author_name'] = data.get('author_name', '').strip()
            if data.get('thumbnail_url'):
                meta['thumbnail_url'] = data.get('thumbnail_url')
    except Exception as e:
        logger.warning(f"YouTube oEmbed fetch error for {video_id}: {e}")

    # 2. If title is still empty, attempt direct scrape of meta title tag
    if not meta['title']:
        try:
            page_url = f"https://www.youtube.com/watch?v={video_id}"
            headers = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"}
            res = requests.get(page_url, headers=headers, timeout=6)
            if res.status_code == 200:
                html = res.text
                title_match = re.search(r'<title>(.*?)</title>', html, re.IGNORECASE)
                if title_match:
                    raw_title = title_match.group(1).replace(' - YouTube', '').strip()
                    meta['title'] = raw_title
        except Exception as e:
            logger.warning(f"YouTube HTML scrape error for {video_id}: {e}")

    if not meta['title']:
        meta['title'] = f"YouTube Video ({video_id})"

    return meta


def generate_smart_fallback_keywords(title: str, channel: str = "") -> List[str]:
    """
    Generates sensible, coherent complete search phrases directly from the video title and channel
    when no AI API key is configured.
    """
    clean_title = re.sub(r'[|\[\]()#_]+', ' ', title).strip()
    words = [w for w in clean_title.split() if w]
    
    phrases = []
    # 1. Full clean title
    if clean_title:
        phrases.append(clean_title)
    
    # 2. Title with channel
    if channel and clean_title:
        phrases.append(f"{clean_title} {channel}")
        phrases.append(f"{channel} {clean_title}")

    # 3. Main keywords from title
    if len(words) > 4:
        phrases.append(" ".join(words[:4]))
        phrases.append(" ".join(words[2:]))
        if channel:
            phrases.append(f"{' '.join(words[:3])} {channel}")

    # Remove duplicates while preserving order
    seen = set()
    result = []
    for p in phrases:
        norm = p.strip().lower()
        if norm and norm not in seen:
            seen.add(norm)
            result.append(p.strip())

    return result or [title or "trending video"]


def get_available_models(provider: str = 'gemini', api_key: str = None) -> List[Dict[str, Any]]:
    """
    Dynamically queries available models from Gemini or OpenRouter.
    """
    settings = AISettings.get_settings()
    provider = (provider or settings.active_provider).lower().strip()

    if provider == 'gemini':
        key = api_key or settings.get_effective_gemini_key()
        if not key:
            raise ValueError("No Google Gemini API key configured.")
        return fetch_gemini_models(key)
    elif provider == 'openrouter':
        key = api_key or settings.get_effective_openrouter_key()
        if not key:
            raise ValueError("No OpenRouter API key configured.")
        return fetch_openrouter_models(key)
    else:
        raise ValueError(f"Unknown AI provider: '{provider}'")


def generate_video_keywords(
    youtube_url_or_id: str,
    title_override: str = None,
    provider_override: str = None,
    model_override: str = None,
) -> Dict[str, Any]:
    """
    Extracts video metadata and generates 6 to 10 high-relevance search phrases using the active LLM.
    Falls back gracefully if no LLM key is configured.
    """
    metadata = extract_youtube_metadata(youtube_url_or_id)
    if title_override:
        metadata['title'] = title_override.strip()

    settings = AISettings.get_settings()
    provider = (provider_override or settings.active_provider).lower().strip()
    system_prompt = settings.custom_system_prompt or "Generate 6-10 realistic YouTube search queries."
    
    keywords: List[str] = []
    used_provider = provider
    used_model = model_override or settings.selected_model or ""

    if settings.is_active:
        # 1. Try preferred provider
        try:
            if provider == 'gemini':
                key = settings.get_effective_gemini_key()
                if key:
                    keywords = generate_keywords_gemini(
                        api_key=key,
                        model=used_model or 'gemini-2.5-flash',
                        video_data=metadata,
                        system_prompt=system_prompt
                    )
            elif provider == 'openrouter':
                key = settings.get_effective_openrouter_key()
                if key:
                    keywords = generate_keywords_openrouter(
                        api_key=key,
                        model=used_model or 'google/gemini-2.5-flash',
                        video_data=metadata,
                        system_prompt=system_prompt
                    )
        except Exception as e:
            logger.warning(f"Preferred provider {provider} encountered error: {e}. Trying alternate provider...")

        # 2. Try alternate provider if primary failed
        if not keywords:
            alternate_provider = 'openrouter' if provider == 'gemini' else 'gemini'
            try:
                if alternate_provider == 'openrouter':
                    alt_key = settings.get_effective_openrouter_key()
                    if alt_key:
                        keywords = generate_keywords_openrouter(
                            api_key=alt_key,
                            model='google/gemini-2.5-flash',
                            video_data=metadata,
                            system_prompt=system_prompt
                        )
                        used_provider = 'openrouter (fallback)'
                elif alternate_provider == 'gemini':
                    alt_key = settings.get_effective_gemini_key()
                    if alt_key:
                        keywords = generate_keywords_gemini(
                            api_key=alt_key,
                            model='gemini-2.5-flash',
                            video_data=metadata,
                            system_prompt=system_prompt
                        )
                        used_provider = 'gemini (fallback)'
            except Exception as alt_err:
                logger.warning(f"Alternate provider {alternate_provider} also failed: {alt_err}")

    # 3. If AI generation didn't run or returned empty, use smart fallback phrases
    if not keywords:
        keywords = generate_smart_fallback_keywords(
            title=metadata.get('title', ''),
            channel=metadata.get('channel', '')
        )
        used_provider = "fallback_smart_parser"

    return {
        'video_id': metadata['video_id'],
        'title': metadata['title'],
        'channel': metadata['channel'],
        'thumbnail_url': metadata['thumbnail_url'],
        'keywords': keywords,
        'provider_used': used_provider,
        'model_used': used_model,
    }
