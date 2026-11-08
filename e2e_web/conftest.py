import pytest

from harness import Browser, real_errors, reseed


@pytest.fixture(scope='session')
def browser():
    b = Browser()
    yield b
    b.close()


@pytest.fixture(autouse=True)
def fresh_data(browser, request):
    """Mỗi test bắt đầu từ dữ liệu mẫu sạch (seed-demo.mjs --reset)."""
    reseed()
    browser.errors.clear()
    yield
    for ctx in list(browser.browser.contexts):
        ctx.close()
    errs = real_errors(browser.errors)
    if errs:
        print('Lỗi console:', *errs, sep='\n  ')
