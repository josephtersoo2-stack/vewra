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
    based on the task's keywords and title.
    """
    keywords = task.keywords if isinstance(task.keywords, list) else []
    title = task.title or ""
    
    # Use user id and task id as seed for deterministic-per-user-session variation if desired,
    # or purely dynamic
    seed_val = f"{user.id if user else 0}_{task.id}_{random.randint(1, 1000)}"
    rng = random.Random(seed_val)

    search_query = ""
    if keywords and len(keywords) > 0:
        # Pick 2-4 keywords or mix with title
        sample_size = min(len(keywords), rng.randint(2, max(2, len(keywords))))
        selected_keywords = rng.sample(keywords, sample_size)
        rng.shuffle(selected_keywords)
        search_query = " ".join(selected_keywords)
    elif title:
        # Fallback to title keywords
        words = [w for w in title.split() if len(w) > 2]
        if words:
            sample_size = min(len(words), rng.randint(3, max(3, len(words))))
            search_query = " ".join(rng.sample(words, sample_size))
        else:
            search_query = title
    else:
        search_query = "trending videos"

    instruction_text = (
        f"1. Tap 'Start Task' to open the YouTube browser.\n"
        f"2. Search YouTube for: \"{search_query}\"\n"
        f"3. Locate and tap the video titled \"{title}\".\n"
        f"4. Watch the video to automatically accumulate rewards!"
    )

    return {
        'search_query': search_query,
        'full_instruction': instruction_text,
        'title': title,
        'thumbnail_url': task.thumbnail_url or (f"https://img.youtube.com/vi/{task.video_id}/hqdefault.jpg" if task.video_id else ""),
    }
