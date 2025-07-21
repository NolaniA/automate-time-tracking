import { chromium } from 'playwright';
import { format, isWeekend } from 'date-fns';

const START_DAY = 6;
const END_DAY = 18;
const START_MONTH = 7;
const START_YEAR = 2025;

const EMPOYEE_NAME = "***-****";   ///nickname-name
const PROJECT_NAME = "futureskill-b2c-learning-platform25";
const COMPANY = "FutureSkill";
const TASK_TYPE = "Idle";
const TASK_ITEM = "พักเที่ยง";
const TASK_NOTE = "-";
const HOURS = "1";

const URL = "https://airtable.com/app6PjJAAPwiRw71N/pagWjJnFT2ZQn7eka/form";

(async () => {
  const browser = await chromium.launch({ headless: false });
  const context = await browser.newContext({
    viewport: { width: 1250, height: 600 },
    userAgent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36",
    // storageState: './trackingstate.json'
  });
  const page = await context.newPage();
  await page.goto(URL, { waitUntil: 'domcontentloaded' });

  // ตรวจสอบว่า login เรียบร้อยด้วยตนเองก่อน
  console.log("Please login manually and press ENTER to continue...");
  await new Promise(resolve => process.stdin.once('data', resolve));

  const workdays = [];
  const totalDays = END_DAY - START_DAY + 1;

  for (let i = 0; i < totalDays; i++) {
    const day = new Date(START_YEAR, START_MONTH - 1, START_DAY + i);
    if (!isWeekend(day)) {
      workdays.push(format(day, 'M/d/yyyy'));
    }
  }
  console.log(workdays);

  for (const day of workdays) {
    await page.waitForSelector('button[type="submit"]', { timeout: 120000 });
    await page.click('button[type="submit"]');

    // ลบข้อมูลเก่า
    const unlinkBtn = page.locator('div[data-testid="unlink-foreign-key"]');
    await unlinkBtn.hover();
    await unlinkBtn.click();
    await unlinkBtn.waitFor({ state: 'detached', timeout: 120000 });

    // ตรวจสอบ error
    await page.waitForSelector('text=This field is required.', { timeout: 120000 });

    // กรอกวันที่
    await page.click('input.date');
    await page.fill('input.date', day);
    await page.keyboard.press('Enter');
    await page.waitForSelector(`input[value="${day}"]`, { timeout: 120000 });

    // กรอกชื่อพนักงาน
    await page.click('button[aria-label="Add employee to Employee field"]');
    await page.fill('div[data-testid="search-input"] input', EMPOYEE_NAME);
    await page.keyboard.press('Enter');
    await page.waitForSelector(`text=${EMPOYEE_NAME}`, { timeout: 120000 });

    // กรอก project
    await page.click('button[aria-label="Add project to Project ID field"]');
    await page.fill('div[data-testid="search-input"] input', PROJECT_NAME);
    await page.keyboard.press('Enter');
    await page.waitForSelector(`text=${PROJECT_NAME}`, { timeout: 120000 });

    // กรอกบริษัท
    await page.click('div[data-tutorial-selector-id="pageCellLabelPairCompany"] button');
    await page.keyboard.type(COMPANY, { delay: 100 });
    await page.keyboard.press('Enter');
    await page.waitForSelector(`div >> text="${COMPANY}"`, { timeout: 120000 });

    // กรอก task type
    await page.click('div[data-testid="autocomplete-button"]');
    await page.keyboard.type(TASK_TYPE);
    await page.keyboard.press('Enter');
    await page.waitForSelector(`div[title="${TASK_TYPE}"]`, { timeout: 120000 });

    // กรอก task item
    await page.click('div[data-tutorial-selector-id="pageCellLabelPairTaskItem"] div[data-testid="cell-editor"]');
    await page.keyboard.type(TASK_ITEM);
    await page.keyboard.press('Enter');
    await page.waitForSelector(`text=${TASK_ITEM}`, { timeout: 120000 });

    // กรอก note
    await page.click('div[data-tutorial-selector-id="pageCellLabelPairTaskNote"] div[data-testid="cell-editor"]');
    await page.keyboard.type(TASK_NOTE);
    await page.keyboard.press('Enter');
    await page.waitForSelector(`textarea >> text=${TASK_NOTE}`, { timeout: 120000 });

    // กรอกเวลาที่ใช้
    await page.click('div[data-tutorial-selector-id="pageCellLabelPairSpentHours"] input');
    await page.fill('div[data-tutorial-selector-id="pageCellLabelPairSpentHours"] input', HOURS);
    await page.keyboard.press('Enter');

    // กด submit
    await page.click('button[type="submit"]');

    // รอข้อความ success
    await page.waitForSelector('text=Thank you for submitting the form!', { timeout: 120000 });

    // refresh เพื่อกรอกวันถัดไป
    await page.click('div.refreshButton');
  }

  console.log("Done!");
  await browser.close();
})();
