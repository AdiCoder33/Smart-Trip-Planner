import pytest


@pytest.mark.django_db
def test_register_and_login(api_client):
    register_resp = api_client.post(
        "/api/auth/register",
        {"email": "new@example.com", "password": "Password123!", "name": "New User"},
        format="json",
    )
    assert register_resp.status_code == 201
    assert register_resp.data["email"] == "new@example.com"

    login_resp = api_client.post(
        "/api/auth/login",
        {"email": "new@example.com", "password": "Password123!"},
        format="json",
    )
    assert login_resp.status_code == 200
    assert "access" in login_resp.data
    assert "refresh" in login_resp.data
