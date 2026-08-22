import pymysql

pymysql.install_as_MySQLdb()

from django.db.backends.mysql.base import DatabaseWrapper
from django.db.backends.mysql.features import DatabaseFeatures

DatabaseWrapper.check_database_version_supported = lambda self: None
DatabaseFeatures.can_return_columns_from_insert = False
DatabaseFeatures.can_return_rows_from_bulk_insert = False

from .celery import app as celery_app

__all__ = ('celery_app',)
