#!/bin/bash

# หา directory ที่ไฟล์นี้อยู่
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "📁 Script directory: $SCRIPT_DIR"

# เข้า directory นั้น
cd "$SCRIPT_DIR" || { echo "❌ ไม่สามารถเข้า directory ได้"; exit 1; }

# 1. ตรวจสอบ Node.js และ npm
if ! command -v node &> /dev/null
then
    echo "❌ Node.js ไม่ได้ติดตั้ง กรุณาติดตั้ง Node.js ก่อน"
    exit 1
fi

echo "✅ พบ Node.js เวอร์ชัน: $(node -v)"
echo "✅ พบ npm เวอร์ชัน: $(npm -v)"

# 2. สร้าง package.json ถ้ายังไม่มี
if [ ! -f package.json ]; then
  npm init -y
  echo "✅ สร้าง package.json เรียบร้อย"
fi

# 3. สร้างโฟลเดอร์ node_modules ถ้ายังไม่มี
if [ ! -d "node_modules" ]; then
  echo "📁 ไม่พบ node_modules สร้างใหม่"
else
  echo "📁 พบ node_modules แล้ว"
fi

# 4. ตรวจสอบและติดตั้ง playwright
npm list playwright &> /dev/null
if [ $? -ne 0 ]; then
  echo "🔄 กำลังติดตั้ง playwright ..."
  npm install playwright
else
  echo "✅ พบแพ็กเกจ playwright แล้ว"
fi

# 5. ตรวจสอบและติดตั้ง date-fns
npm list date-fns &> /dev/null
if [ $? -ne 0 ]; then
  echo "🔄 กำลังติดตั้ง date-fns ..."
  npm install date-fns
else
  echo "✅ พบแพ็กเกจ date-fns แล้ว"
fi


# JSON_FILE="trackingstate.json"
# if [ ! -f "$JSON_FILE" ]; then
# cat << 'EOF' > "$JSON_FILE"
# {
#   "cookies": [
#     { "name": "brw", "value": "brwIbzuUg2H9VTMHB" , "url": "https://airtable.com"},
#     { "name": "pxcts", "value": "5afbbdbb-63ec-11f0-b5b5-500a48b67f01", "url": "https://airtable.com" },
#     { "name": "_pxvid", "value": "5afbb391-63ec-11f0-b5b4-39aebecd9667", "url": "https://airtable.com" },
#     { "name": "login-status-p", "value": "eyJhbGciOiJFUzI1NiJ9.dXNyeFowYjM2VlFoUDdhZTg.nN9K1D30DystTI4MOaZObK7WlXeiYXx5w3MkqrmATF4xz4xYmaj6ToFFfVn8UEucio7-41vcQ-tn1weaLOmAfQ", "url": "https://airtable.com" },
#     { "name": "mv", "value": "eyJzdGFydFRpbWUiOiIyMDI1LTA3LTE4VDE1OjMyOjExLjY4MFoiLCJsb2NhdGlvbiI6Imh0dHBzOi8vYWlydGFibGUuY29tL2xvZ2luP2NvbnRpbnVlPSoiLCJpbnRlcm5hbFRyYWNlSWQiOiJ0cmNibTBpNlVxTVNrcXBEVSJ9", "url": "https://airtable.com" },
#     { "name": "_mkto_trk", "value": "id:458-JHQ-131&token:_mch-airtable.com-c6357617d879ed6ee8fc71b8b4c1a9f9", "url": "https://airtable.com" },
#     { "name": "__stripe_mid", "value": "36fd8d72-7e2b-4847-9cc5-bb8f453c99743ccb82", "url": "https://airtable.com" },
#     { "name": "__stripe_sid", "value": "41074ef6-e01e-4f27-a8e7-5c7da84ae0f964197b" , "url": "https://airtable.com"},
#     { "name": "OptanonConsent", "value": "isGpcEnabled=0&datestamp=Fri+Jul+18+2025+22%3A59%3A39+GMT%2B0700+(Indochina+Time)&version=202407.1.0&browserGpcFlag=0&isIABGlobal=false&hosts=&consentId=2abf38ed-6704-4dd3-9431-4b077b643240&interactionCount=1&isAnonUser=1&landingPath=NotLandingPage&groups=C0001%3A1%2CC0002%3A1%2CC0007%3A1%2CC0003%3A1%2CC0004%3A1&AwaitingReconsent=false", "url": "https://airtable.com" },
#     { "name": "AWSALBTG", "value": "IkNrWe7M2mYY8D2JnZrVgQ2Cn3QBkgKrmylw1k64GDXYN15ic+v1sCQGrA+K6xD+rGM0FqW4ZoOFsjwECHXK7+beigFLgBejAgagRRng8L527LhlWO289jfOe4WU7VG8xO27d6H9VOjvBonr4hKrfrXbzkmWkAXZjIgu9mSIZjYoMVpvOu4=" , "url": "https://airtable.com"},
#     { "name": "AWSALBTGCORS", "value": "OmV0wVRjnNr1qiHiHkupFOtPV399qtS+2a06HgsFTtYJvKg1gscAOhwLGKDd+grjrxr8L5ybpeKUWi8LdLq/1/A5ybIXYuA0bTkHGNtx/f1d7LTVMFXxB26nuvjRGlET21yfXbsflUbWNCICwJstif6Uv/zYL+IzwPrswt5jKJsMeV7GHzw=", "url": "https://airtable.com" }
#   ]
# }
# EOF

# 6. สร้างไฟล์ airtable_submit.mjs ถ้ายังไม่มี
SCRIPT_FILE="airtable_submit.mjs"
# if [ ! -f "$SCRIPT_FILE" ]; then
cat << 'EOF' > "$SCRIPT_FILE"
import { chromium } from 'playwright';
import { format, isWeekend } from 'date-fns';

const START_DAY = 23;
const END_DAY = 24;
const START_MONTH = 7;
const START_YEAR = 2025;

const EMPOYEE_NAME = "นุ้ย-ณัฐกานต์";
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

    const unlinkBtn = page.locator('div[data-testid="unlink-foreign-key"]');
    await unlinkBtn.hover();
    await unlinkBtn.click();
    await unlinkBtn.waitFor({ state: 'detached', timeout: 120000 });

    await page.waitForSelector('text=This field is required.', { timeout: 120000 });

    await page.click('input.date');
    await page.fill('input.date', day);
    await page.keyboard.press('Enter');
    await page.waitForSelector(`input[value="${day}"]`, { timeout: 120000 });

    await page.click('button[aria-label="Add employee to Employee field"]');
    await page.fill('div[data-testid="search-input"] input', EMPOYEE_NAME);
    await page.keyboard.press('Enter');
    await page.waitForSelector(`text=${EMPOYEE_NAME}`, { timeout: 120000 });

    await page.click('button[aria-label="Add project to Project ID field"]');
    await page.fill('div[data-testid="search-input"] input', PROJECT_NAME);
    await page.keyboard.press('Enter');
    await page.waitForSelector(`text=${PROJECT_NAME}`, { timeout: 120000 });

    await page.click('div[data-tutorial-selector-id="pageCellLabelPairCompany"] button');
    await page.keyboard.type(COMPANY, { delay: 100 });
    await page.keyboard.press('Enter');
    await page.waitForSelector(`div >> text="${COMPANY}"`, { timeout: 120000 });

    await page.click('div[data-testid="autocomplete-button"]');
    await page.keyboard.type(TASK_TYPE);
    await page.keyboard.press('Enter');
    await page.waitForSelector(`div[title="${TASK_TYPE}"]`, { timeout: 120000 });

    await page.click('div[data-tutorial-selector-id="pageCellLabelPairTaskItem"] div[data-testid="cell-editor"]');
    await page.keyboard.type(TASK_ITEM);
    await page.keyboard.press('Enter');
    await page.waitForSelector(`text=${TASK_ITEM}`, { timeout: 120000 });

    await page.click('div[data-tutorial-selector-id="pageCellLabelPairTaskNote"] div[data-testid="cell-editor"]');
    await page.keyboard.type(TASK_NOTE);
    await page.keyboard.press('Enter');
    await page.waitForSelector(`textarea >> text=${TASK_NOTE}`, { timeout: 120000 });

    await page.click('div[data-tutorial-selector-id="pageCellLabelPairSpentHours"] input');
    await page.fill('div[data-tutorial-selector-id="pageCellLabelPairSpentHours"] input', HOURS);
    await page.keyboard.press('Enter');

    await page.click('button[type="submit"]');

    await page.waitForSelector('div.refreshButton', { timeout: 200000 });

    await page.click('div.refreshButton');
  }

  console.log("Done!");
  await browser.close();
})();
EOF
  echo "✅ สร้างไฟล์ $SCRIPT_FILE เรียบร้อย"
# fi

# 7. รันสคริปต์
echo "🚀 กำลังรันสคริปต์..."
node "$SCRIPT_FILE"

# # 8. ลบไฟล์ที่สร้างทั้งหมด
# echo "🧹 กำลังลบไฟล์ที่สร้าง..."
# rm -f "$SCRIPT_FILE"
# echo "🗑️ ลบไฟล์ $SCRIPT_FILE แล้ว"

echo "✅ เสร็จสิ้น!"