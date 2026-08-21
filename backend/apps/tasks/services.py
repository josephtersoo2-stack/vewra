import re
import random
from urllib.parse import urlparse, parse_qs

YOUTUBE_REGEX = re.compile(
    r'(?:https?:\/\/)?(?:www\.|m\.)?(?:youtube\.com\/(?:watch\?(?:.*&)?v=|embed\/|v\/|shorts\/)|youtu\.be\/)([\w-]{11})',
    re.IGNORECASE
)

def extract_youtube_video_id(url: str) -> str:
    """
    Extract 11-character YouTube video ID from various URL formats.
    """
    if not url:
        return ""
    
    url = url.strip()
    match = YOUTUBE_REGEX.search(url)
    if match:
        return match.group(1)
    
    # Fallback to query param parsing
    try:
        parsed = urlparse(url)
        if 'youtube' in parsed.netloc:
            qs = parse_qs(parsed.query)
            if 'v' in qs and qs['v']:
                return qs['v'][0]
    except Exception:
        pass

    # If the user directly entered the 11-character ID
    if len(url) == 11 and re.match(r'^[\w-]+$', url):
        return url

    return ""

def generate_randomized_instruction(task, user=None) -> dict:
    """
    Generates a personalized randomized search instruction for the user
    based on the task's AI-generated keyword search phrases and title.
    """
    keywords = [str(k).strip() for k in task.keywords] if isinstance(task.keywords, list) else []
    keywords = [k for k in keywords if k]
    title = (task.title or "").strip()
    
    # Use user id and task id as seed for deterministic-per-user-session variation
    seed_val = f"{user.id if user else 0}_{task.id}_{random.randint(1, 1000)}"
    rng = random.Random(seed_val)

    search_query = ""
    if keywords:
        # Select one high-relevance search phrase from the keyword options
        search_query = rng.choice(keywords)
    elif title:
        search_query = title
    else:
        search_query = "trending videos"

    instruction_text = (
        f"1. Tap 'Start Task' to open YouTube in the browser.\n"
        f"2. Copy and paste (or type) this search query into YouTube: \"{search_query}\"\n"
        f"3. Locate and tap the video matching \"{title}\".\n"
        f"4. Watch the video to automatically accumulate rewards!"
    )

    return {
        'search_query': search_query,
        'full_instruction': instruction_text,
        'title': title,
        'thumbnail_url': task.thumbnail_url or (f"https://img.youtube.com/vi/{task.video_id}/hqdefault.jpg" if task.video_id else ""),
    }
