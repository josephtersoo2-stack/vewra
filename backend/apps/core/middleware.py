import uuid
import time
import logging
from django.utils.deprecation import MiddlewareMixin

logger = logging.getLogger('vewra.request')

class RequestCorrelationMiddleware(MiddlewareMixin):
    """
    Middleware that ensures every request has an X-Request-ID for distributed tracing.
    Logs structured lifecycle metrics for all incoming requests.
    """

    def process_request(self, request):
        request_id = request.headers.get('X-Request-ID') or str(uuid.uuid4())
        request.request_id = request_id
        request._start_time = time.time()

    def process_response(self, request, response):
        request_id = getattr(request, 'request_id', str(uuid.uuid4()))
        response['X-Request-ID'] = request_id

        # Security Headers (FIX-03)
        response['X-Content-Type-Options'] = 'nosniff'
        response['X-Frame-Options'] = 'DENY'
        response['Referrer-Policy'] = 'strict-origin-when-cross-origin'
        response['Cross-Origin-Opener-Policy'] = 'same-origin'

        # Calculate duration
        start_time = getattr(request, '_start_time', None)
        if start_time:
            duration_ms = round((time.time() - start_time) * 1000, 2)
            user_identifier = request.user.username if (hasattr(request, 'user') and request.user.is_authenticated) else 'anonymous'
            
            # Log structured summary (excluding noisy healthchecks)
            if not request.path.startswith('/health'):
                logger.info(
                    f"[{request_id}] {request.method} {request.path} -> {response.status_code} ({duration_ms}ms) user={user_identifier}"
                )

        return response
