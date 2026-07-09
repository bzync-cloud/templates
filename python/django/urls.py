from django.http import JsonResponse
from django.urls import path


def health(request):
    return JsonResponse({"status": "ok"})


def index(request):
    return JsonResponse({"message": "Welcome to the API"})


urlpatterns = [
    path("health/", health),
    path("", index),
]
