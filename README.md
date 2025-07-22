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

Skip login 

  step1: manual login
  
  step2: save storagestate
    - robot: Save Storage State
    - playwright: await context.storageState({ path: 'auth.json' });
    
  step3: 
    - robot: New Context    storageState=${CURDIR}${/}auth.json  ...
    - playwright:const context = await browser.newContext({storageState: './auth.json'}  ...)

  step4: runnnnn!!
    
