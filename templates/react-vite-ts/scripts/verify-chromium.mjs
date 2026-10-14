import { chromium } from '@playwright/test'

const browser = await chromium.launch({ headless: true })
try {
  const page = await browser.newPage()
  await page.goto('data:text/html,<title>ADEL Chromium probe</title>')
  if (await page.title() !== 'ADEL Chromium probe') throw new Error('Chromium navigation failed')
  console.log(`Chromium available: ${browser.version()}`)
} finally {
  await browser.close()
}
