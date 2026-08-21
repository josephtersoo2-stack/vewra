from django.urls import path
from apps.tasks.views import TaskListView, TaskDetailView, TaskStartView

urlpatterns = [
    path('', TaskListView.as_view(), name='task_list'),
    path('<int:pk>/', TaskDetailView.as_view(), name='task_detail'),
    path('<int:pk>/start/', TaskStartView.as_view(), name='task_start'),
]
