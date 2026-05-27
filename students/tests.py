from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from .models import Student


class StudentCRUDTests(APITestCase):
    def setUp(self):
        self.list_url = reverse('student-list-create')
        self.student = Student.objects.create(
            first_name='Ada',
            last_name='Lovelace',
            email='ada@school.edu',
            enrollment_number='ENR001',
        )
        self.detail_url = reverse('student-detail', args=[self.student.id])

    # --- Create ---
    def test_create_student(self):
        payload = {
            'first_name': 'Alan',
            'last_name': 'Turing',
            'email': 'alan@school.edu',
            'enrollment_number': 'ENR002',
        }
        response = self.client.post(self.list_url, payload, format='json')

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(Student.objects.count(), 2)
        self.assertEqual(response.data['first_name'], 'Alan')
        self.assertIn('id', response.data)

    def test_create_student_missing_required_field(self):
        payload = {'first_name': 'NoLastName', 'email': 'x@school.edu'}
        response = self.client.post(self.list_url, payload, format='json')

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(Student.objects.count(), 1)

    def test_create_student_duplicate_email_rejected(self):
        payload = {
            'first_name': 'Dup',
            'last_name': 'Email',
            'email': 'ada@school.edu',  # already used in setUp
            'enrollment_number': 'ENR999',
        }
        response = self.client.post(self.list_url, payload, format='json')

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('email', response.data)

    # --- Read ---
    def test_list_students(self):
        response = self.client.get(self.list_url)

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)

    def test_retrieve_student(self):
        response = self.client.get(self.detail_url)

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['enrollment_number'], 'ENR001')

    def test_retrieve_missing_student_returns_404(self):
        url = reverse('student-detail', args=[9999])
        response = self.client.get(url)

        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

    # --- Update ---
    def test_update_student_put(self):
        payload = {
            'first_name': 'Ada',
            'last_name': 'King',
            'email': 'ada@school.edu',
            'enrollment_number': 'ENR001',
        }
        response = self.client.put(self.detail_url, payload, format='json')

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.student.refresh_from_db()
        self.assertEqual(self.student.last_name, 'King')

    def test_partial_update_student_patch(self):
        response = self.client.patch(
            self.detail_url, {'last_name': 'Byron'}, format='json'
        )

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.student.refresh_from_db()
        self.assertEqual(self.student.last_name, 'Byron')

    # --- Delete ---
    def test_delete_student(self):
        response = self.client.delete(self.detail_url)

        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)
        self.assertEqual(Student.objects.count(), 0)
