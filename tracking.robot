*** Settings ***
Library    Dialogs
Library    Browser    
Library    Collections

*** Variables ***

${START_DAY}    6
${END_DAY}    18
${START_MONTH}    7
${START_YEAR}    2025
${EMPOYEE_NAME}    ***-******        # nickname-name
${PROJECT_NAME}    futureskill-b2c-learning-platform25
${COMPANY}    FutureSkill
${TASK_TYPE}    Idle
${TASK_ITEM}    พักเที่ยง
${TASK_NOTE}    -
${HOURS}    1
${URL}    https://airtable.com/app6PjJAAPwiRw71N/pagWjJnFT2ZQn7eka/form 





*** Test Cases ***
Tracking
    [Tags]    test
    New Browser    chromium    headless=${False}    
    New Context    
        # ...    storageState=${CURDIR}${/}trackingstate.json
        ...    viewport={'width': 1250, 'height': 600}    
        ...    userAgent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36
    New Page    ${URL}   wait_until=domcontentloaded

    Execute Manual Step    manual login success?

    # set date time
    @{days_work}    Create List
    ${range_end}    Evaluate    (int(${END_DAY}) - int(${START_DAY})) + 1
    FOR    ${index}    IN RANGE    0    ${range_end}
        ${dt}    Evaluate    datetime.datetime(${START_YEAR}, ${START_MONTH}, ${START_DAY}) + datetime.timedelta(days=${index})    modules=datetime
        # skip saturday and sunday
        Continue For Loop If    ${dt.weekday()} == ${0} or ${dt.weekday()} == ${6}
        # get day work
        ${format_day}    Set Variable    ${dt.month}/${dt.day}/${dt.year}
        Append To List    ${days_work}    ${format_day}
    END
    Log    ${days_work}    console=${False}

    # loop submit Lunch break
    FOR    ${day}    IN    @{days_work}
        
        # wait page loading and click submit check ready run
        Wait Until Keyword Succeeds    2m    2s    
            ...    Get Element Count    
            ...    button[type="submit"]    >=    1

        Click    button[type="submit"]

        # clear auto fill
        Hover    div[data-testid="unlink-foreign-key"]
        Click    div[data-testid="unlink-foreign-key"]
        Wait Until Keyword Succeeds    2m    1s    
            ...    Get Element Count    
            ...    div[data-testid="unlink-foreign-key"]    ==    0 


        # wait page error
        Wait Until Keyword Succeeds    2m    2s    
            ...    Get Element Count    
            ...    text=This field is required.    >=    1

        # fill date
        Click    input.date
        Type Text    input.date    ${day}
        Keyboard Key    press    Enter
        Wait Until Keyword Succeeds    2m    1s    
            ...    Get Element Count    
            ...    input[value="${day}"]    >=    1 


        # fill employee
        Click    button[aria-label="Add employee to Employee field"]
        Get Element Count    div[data-testid="search-input"] input    >=    1
        Type Text    div[data-testid="search-input"] input    ${EMPOYEE_NAME}
        Keyboard Key    press    Enter
        Wait Until Keyword Succeeds    2m    1s    
            ...    Get Element Count     
            ...    text=${EMPOYEE_NAME}    >=    1
        
        # fill Project 
        Click    button[aria-label="Add project to Project ID field"]
        Get Element Count    div[data-testid="search-input"] input    >=    1
        Type Text    div[data-testid="search-input"] input    ${PROJECT_NAME}
        Keyboard Key    press    Enter
        Wait Until Keyword Succeeds    2m    1s    
            ...    Get Element Count     
            ...    text=${PROJECT_NAME}    >=    1

        # fill company
        Wait Until Keyword Succeeds    2m    1s    
            ...    Get Element Count     
            ...    div[data-tutorial-selector-id="pageCellLabelPairCompany"] button    >=    1
        Click    div[data-tutorial-selector-id="pageCellLabelPairCompany"] button
        Keyboard Input    insertText    ${COMPANY}    delay=0.3s
        Keyboard Key    press    Enter
        Wait Until Keyword Succeeds    2m    1s    
            ...    Get Element Count     
            ...    div >> text="${COMPANY}"    >=    1

        # fill task type
        Click    div[data-testid="autocomplete-button"]
        Keyboard Input    insertText    ${TASK_TYPE}
        Keyboard Key    press    Enter
        Wait Until Keyword Succeeds    2m    1s    
            ...    Get Element Count     
            ...    div[title="${TASK_TYPE}"]    >=    1


        # fill task item
        Click    div[data-tutorial-selector-id="pageCellLabelPairTaskItem"] div[data-testid="cell-editor"]
        Keyboard Input    insertText    ${TASK_ITEM}
        Keyboard Key    press    Enter
        Wait Until Keyword Succeeds    2m    1s    
            ...    Get Element Count     
            ...    text=${TASK_ITEM}    >=    1

        # fill task note
        Click    div[data-tutorial-selector-id="pageCellLabelPairTaskNote"] div[data-testid="cell-editor"]
        Keyboard Input    insertText    ${TASK_NOTE}
        Keyboard Key    press    Enter
        Wait Until Keyword Succeeds    2m    1s    
            ...    Get Element Count     
            ...    textarea >> text=${TASK_NOTE}    >=    1

        # fill spent time
        Click    div[data-tutorial-selector-id="pageCellLabelPairSpentHours"] input
        Type Text    div[data-tutorial-selector-id="pageCellLabelPairSpentHours"] input    ${HOURS}
        Keyboard Key    press    Enter

        # submit
        Click    button[type="submit"]

        # wait submit success
        Wait Until Keyword Succeeds    2m    1s    
            ...    Get Element Count     
            ...    text=Thank you for submitting the form!    >=    1
        Click    div.refreshButton


        
    END
    

    # ${state_file} =    Save Storage State
    # Create File    ${CURDIR}${/}trackingstate.json    ${state_file}



    Pause Execution


*** Keywords ***