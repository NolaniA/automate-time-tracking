tracking

playwright (javaScript) : https://playwright.dev/docs/intro
  install:
    - install node >> https://nodejs.org
    - npm init -y
    - npm install -D @playwright/test
    - npx playwright install
  How to run:
    node filename.js
    # หรือ
    node filename.mjs
  

Robot framework (Browser library) : https://robotframework.org/
  install:
    - install node >> https://nodejs.org
    - install python >> https://www.python.org/downloads/
    - install browser lib
      - pip install -U robotframework-browser
      - rfbrowser clean-node
      - rfbrowser init
 How to run:
   - robot filename.py
