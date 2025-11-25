# backend/routes/apply_placementindia.py
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, HttpUrl
from typing import Optional
import time

from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.chrome.options import Options


router = APIRouter(prefix="/api/apply", tags=["apply"])


class PlacementIndiaApplyRequest(BaseModel):
    job_url: HttpUrl
    email: str
    password: str


class PlacementIndiaApplyResponse(BaseModel):
    success: bool
    step: str
    message: Optional[str] = None


def _make_driver(headless: bool = False) -> webdriver.Chrome:
    opts = Options()
    if headless:
        opts.add_argument("--headless=new")
    opts.add_argument("--window-size=1400,900")
    opts.add_argument("--disable-gpu")
    opts.add_argument("--no-sandbox")
    opts.add_argument(
        "--user-agent=Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    )
    driver = webdriver.Chrome(options=opts)
    return driver


@router.post("/placementindia", response_model=PlacementIndiaApplyResponse)
def apply_placementindia(payload: PlacementIndiaApplyRequest):
    driver = None
    try:
        driver = _make_driver(headless=False)  # visible for demo
        driver.get(str(payload.job_url))

        wait = WebDriverWait(driver, 20)

        # 1) Click "Apply Now" button (id="applyJob" inside div.btns-apply)
        apply_btn = wait.until(
            EC.element_to_be_clickable((By.ID, "applyJob"))
        )
        apply_btn.click()

        # 2) Wait for login modal/email form and submit email
        # Form id="login", field id="user_name"
        email_input = wait.until(
            EC.visibility_of_element_located((By.ID, "user_name"))
        )
        email_input.clear()
        email_input.send_keys(payload.email)

        # Submit the email step - button[type=submit] inside the same form
        email_form = driver.find_element(By.ID, "login")
        submit_btn = email_form.find_element(By.CSS_SELECTOR, "button[type='submit']")
        submit_btn.click()

        # 3) Wait for password form: id="passwordProcess", input id="userPassword"
        pwd_input = wait.until(
            EC.visibility_of_element_located((By.ID, "userPassword"))
        )
        pwd_input.clear()
        pwd_input.send_keys(payload.password)

        # Click Login submit in password form
        pwd_form = driver.find_element(By.ID, "passwordProcess")
        login_btn = pwd_form.find_element(By.CSS_SELECTOR, "button[type='submit']")
        login_btn.click()

        # 4) Basic outcome check: wait briefly; detect error banner or modal close
        time.sleep(3)
        # Check for incorrect password error if visible
        try:
            err = driver.find_element(By.CSS_SELECTOR, ".errow_mess ._erro_mm")
            if err and err.is_displayed() and "incorrect" in err.text.lower():
                return PlacementIndiaApplyResponse(
                    success=False,
                    step="password",
                    message="Incorrect password or login failed.",
                )
        except Exception:
            pass

        return PlacementIndiaApplyResponse(
            success=True,
            step="submitted",
            message="Login attempted; if credentials are valid, application should proceed.",
        )

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"PlacementIndia apply failed: {e}")
    finally:
        try:
            if driver is not None:
                driver.quit()
        except Exception:
            pass
