from rest_framework import generics

from .models import Student
from .serializers import StudentSerializer


class StudentListCreateView(generics.ListCreateAPIView):
    """GET  /api/students/      -> list students (Read)
    POST /api/students/      -> add a student (Create)
    """
    queryset = Student.objects.all()
    serializer_class = StudentSerializer


class StudentRetrieveUpdateDestroyView(generics.RetrieveUpdateDestroyAPIView):
    """GET    /api/students/<id>/  -> single student (Read)
    PUT    /api/students/<id>/  -> update a student (Update)
    DELETE /api/students/<id>/  -> remove a student (Delete)
    """
    queryset = Student.objects.all()
    serializer_class = StudentSerializer
