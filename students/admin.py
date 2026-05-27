from django.contrib import admin

from .models import Student


@admin.register(Student)
class StudentAdmin(admin.ModelAdmin):
    list_display = ['enrollment_number', 'first_name', 'last_name', 'email']
    search_fields = ['first_name', 'last_name', 'email', 'enrollment_number']
