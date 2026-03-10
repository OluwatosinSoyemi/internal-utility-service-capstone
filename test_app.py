import pytest
from app import app


@pytest.fixture
def client():
    app.testing = True
    with app.test_client() as c:
        yield c


def test_health(client):
    res = client.get("/health")
    assert res.status_code == 200
    assert res.get_json() == {"status": "UP"}


def test_sum(client):
    res = client.post("/sum", json={"a": 5, "b": 10})
    assert res.status_code == 200
    assert res.get_json()["result"] == 15


def test_reverse(client):
    res = client.post("/reverse-string", json={"text": "hello"})
    assert res.status_code == 200
    assert res.get_json()["result"] == "olleh"


def test_sum_with_negative(client):
    res = client.post("/sum", json={"a": -5, "b": 10})
    assert res.status_code == 200
    assert res.get_json()["result"] == 5


def test_sum_with_zero(client):
    res = client.post("/sum", json={"a": 0, "b": 0})
    assert res.status_code == 200
    assert res.get_json()["result"] == 0


def test_reverse_empty_string(client):
    res = client.post("/reverse-string", json={"text": ""})
    assert res.status_code == 200
    assert res.get_json()["result"] == ""


def test_reverse_single_char(client):
    res = client.post("/reverse-string", json={"text": "a"})
    assert res.status_code == 200
    assert res.get_json()["result"] == "a"


def test_reverse_with_spaces(client):
    res = client.post("/reverse-string", json={"text": "hi there"})
    assert res.status_code == 200
    assert res.get_json()["result"] == "ereht ih"
