from django.apps import AppConfig

class SettingsAppConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'settings_app'

    def ready(self):
        import settings_app.signals  # noqa