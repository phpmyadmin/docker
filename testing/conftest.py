import pytest

def pytest_addoption(parser):
    parser.addoption("--url")
    parser.addoption("--username")
    parser.addoption("--password")
    parser.addoption("--server")
    parser.addoption("--sqlfile")

@pytest.fixture
def url(request):
    return request.config.getoption("--url")

@pytest.fixture
def username(request):
    return request.config.getoption("--username")

@pytest.fixture
def password(request):
    return request.config.getoption("--password")

@pytest.fixture
def server(request):
    return request.config.getoption("--server")
    
@pytest.fixture
def sqlfile(request):
    return request.config.getoption("--sqlfile")
