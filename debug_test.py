"""Quick debug test to check for JavaScript errors"""

import time
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.options import Options
import os

def run_debug():
    file_path = os.path.join(os.path.dirname(__file__), "meta-sprint-v3_0-2.html")
    file_url = f"file:///{file_path.replace(os.sep, '/')}"

    options = Options()
    options.add_argument('--start-maximized')
    options.set_capability('goog:loggingPrefs', {'browser': 'ALL'})
    driver = webdriver.Chrome(options=options)

    try:
        driver.get(file_url)
        time.sleep(2)

        print("=== BROWSER CONSOLE ===")
        for entry in driver.get_log('browser'):
            print(f"  {entry['level']}: {entry['message']}")

        # Check if app has JavaScript errors
        has_errors = driver.execute_script("return window.getProject !== undefined")
        print(f"\ngetProject function exists: {has_errors}")

        if has_errors:
            project = driver.execute_script("return JSON.stringify(getProject())")
            print(f"Current project: {project[:200] if project else 'null'}...")

    except Exception as e:
        print(f"ERROR: {e}")
    finally:
        time.sleep(2)
        driver.quit()

if __name__ == "__main__":
    run_debug()
