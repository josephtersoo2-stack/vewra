import json
import logging
import requests
from typing import List, Dict, Any

logger = logging.getLogger(__name__)

OPENROUTER_BASE_URL = "https://openrouter.ai/api/v1"

def fetch_openrouter_models(api_key: str) -> List[Dict[str, Any]]:
    """
    Dynamically queries OpenRouter API for available models.
    No hardcoded models.
    """
    if not api_key:
        raise ValueError("OpenRouter API key is required to fetch models.")

    url = f"{OPENROUTER_BASE_URL}/models"
    headers = {
        "Authorization": f"Bearer {api_key.strip()}",
        "HTTP-Referer": "https://vewra.app",
        "X-Title": "Vewra Video Tasks",
    }
    
    response = requests.get(url, headers=headers, timeout=12)
    if response.status_code != 200:
        error_msg = response.text
        try:
            err_json = response.json()
            error_msg = err_json.get('error', {}).get('message', error_msg)
        except Exception:
            pass
        raise RuntimeError(f"OpenRouter API error ({response.status_code}): {error_msg}")

    data = response.json()
    models_raw = data.get('data', [])
    
    parsed_models = []
    for m in models_raw:
        model_id = m.get('id', '')
        if model_id:
            parsed_models.append({
                'id': model_id,
                'name': m.get('name', model_id),
                'description': m.get('description', ''),
                'context_length': m.get('context_length', 0),
            })

    # Sort popular / fast models to the top
    def _sort_weight(item):
        mid = item['id'].lower()
        if 'flash' in mid or 'mini' in mid or 'free' in mid:
            return 3
        if 'gemini' in mid or 'llama' in mid or 'claude' in mid or 'gpt-4o' in mid:
            return 2
        return 1

    parsed_models.sort(key=_sort_weight, reverse=True)
    return parsed_models


def generate_keywords_openrouter(
    api_key: str,
    model: str,
    video_data: Dict[str, Any],
    system_prompt: str
) -> List[str]:
    """
    Calls OpenRouter chat completions API to generate high-relevance search keywords.
    """
    if not api_key:
        raise ValueError("OpenRouter API key is missing.")
    
    model_name = model.strip() if model else "google/gemini-2.5-flash"

    url = f"{OPENROUTER_BASE_URL}/chat/completions"
    headers = {
        "Authorization": f"Bearer {api_key.strip()}",
        "Content-Type": "application/json",
        "HTTP-Referer": "https://vewra.app",
        "X-Title": "Vewra Video Tasks",
    }

    user_prompt = f"""VIDEO DETAILS:
- Title: {video_data.get('title', '')}
- Channel / Author: {video_data.get('channel', video_data.get('author_name', ''))}
- Video ID: {video_data.get('video_id', '')}
- Description: {video_data.get('description', '')[:500]}

Generate 6 to 10 natural, highly-relevant search query phrases that real viewers would type into the YouTube search bar to find this exact video.
Return ONLY a valid JSON array of strings: ["phrase 1", "phrase 2", "phrase 3", ...]
"""

    payload = {
        "model": model_name,
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_prompt}
        ],
        "temperature": 0.3,
    }

    response = requests.post(url, headers=headers, json=payload, timeout=25)
    if response.status_code != 200:
        error_msg = response.text
        try:
            err_json = response.json()
            error_msg = err_json.get('error', {}).get('message', error_msg)
        except Exception:
            pass
        raise RuntimeError(f"OpenRouter generation error ({response.status_code}): {error_msg}")

    data = response.json()
    choices = data.get('choices', [])
    if not choices:
        raise RuntimeError("OpenRouter returned no choices.")

    content = choices[0].get('message', {}).get('content', '')
    return _parse_json_keywords(content, fallback_title=video_data.get('title', ''))


def _parse_json_keywords(raw_text: str, fallback_title: str) -> List[str]:
    cleaned = raw_text.strip()
    if cleaned.startswith("```json"):
        cleaned = cleaned[7:]
    elif cleaned.startswith("```"):
        cleaned = cleaned[3:]
    if cleaned.endswith("```"):
        cleaned = cleaned[:-3]
    cleaned = cleaned.strip()

    try:
        keywords = json.loads(cleaned)
        if isinstance(keywords, list):
            valid_list = [str(k).strip() for k in keywords if str(k).strip()]
            if valid_list:
                return valid_list
    except Exception as e:
        logger.warning(f"Failed to parse JSON from LLM: {e}, raw text: {cleaned}")

    lines = [line.strip().strip('-*•1234567890. "') for line in raw_text.splitlines() if line.strip()]
    if lines:
        return [l for l in lines if len(l) > 3][:10]

    return [fallback_title] if fallback_title else ["trending video"]
