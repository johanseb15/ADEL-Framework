import { test, expect } from '@playwright/test'

test('home interaction and review capture', async ({ page }, testInfo) => {
  await page.goto('/')
  await expect(page.getByRole('heading', { name: 'New ADEL project' })).toBeVisible()
  await page.getByRole('button', { name: 'Count: 0' }).click()
  await expect(page.getByRole('button', { name: 'Count: 1' })).toBeVisible()
  const path = testInfo.outputPath('home-desktop.png')
  await page.screenshot({ path, fullPage: true })
  await testInfo.attach('home-desktop', { path, contentType: 'image/png' })
})
