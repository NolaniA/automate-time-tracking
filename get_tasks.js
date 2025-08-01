const fs = require('fs');


(async () => {
  try {
    const headers = {
      'x-access-token': 'test'
    };

    const params = {
      user: 29,
      page: 1,
      limit: 10000
    };

    const queryString = new URLSearchParams(params).toString();
    const url = `https://github-action-tracker.pages.dev/api/action-runs?${queryString}`;
    const response = await fetch(url, {method: 'GET', headers});
    const data = await response.json();


    const result = {};

    for (const item of data.data) {
      const action_run = item.action_run;
      const display_title = action_run.display_title;

      const is_create = /^feat:/i.test(display_title);
      const is_bug = /^fix:/i.test(display_title);
      if (!is_create && !is_bug) continue;

      let action = display_title;
      if (is_create) action = action.replace(/^feat:\s🎸/i, 'Create');
      if (is_bug) action = action.replace(/^fix:\s🐛/i, 'Bug fix');

      const crate_date = new Date(action_run.createdAt);
      const year = crate_date.getFullYear();
      const month = String(crate_date.getMonth() + 1).padStart(2, '0');
      const day = String(crate_date.getDate()).padStart(2, '0');
      const dt_format = `${year}-${month}-${day}`;

      const type = is_create ? 'work' : 'fix';
      const hours = is_create ? '1' : '2';

      const temp = {
        task: action,
        type: type,
        hours: hours
      };

      if (!result[dt_format]) {
        result[dt_format] = [temp];
      } else {
        const alreadyExists = result[dt_format].some(
          t => t.task === temp.task && t.type === temp.type && t.hours === temp.hours
        );
        if (!alreadyExists) {
          result[dt_format].push(temp);
        }
      }
    }

    const outputPath = `${__dirname}/daily_taskss.json`;
    fs.writeFileSync(outputPath, JSON.stringify(result, null, 2), 'utf-8');
    console.log(`✅ Saved to ${outputPath}`);
  } catch (error) {
    console.error('❌ Error:', error.message);
  }
})();
