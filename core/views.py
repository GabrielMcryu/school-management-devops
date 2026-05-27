from django.db import connection
from django.http import JsonResponse


def health(request):
    """Liveness/readiness probe. Returns 200 if the app can reach the database."""
    try:
        with connection.cursor() as cursor:
            cursor.execute('SELECT 1')
            cursor.fetchone()
        db_ok = True
    except Exception:
        db_ok = False

    status = 200 if db_ok else 503
    return JsonResponse(
        {'status': 'ok' if db_ok else 'unhealthy', 'database': 'up' if db_ok else 'down'},
        status=status,
    )
