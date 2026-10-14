import { cleanup, fireEvent, render, screen } from '@testing-library/react'
import { afterEach, expect, test } from 'vitest'
import App from './App'

afterEach(cleanup)
test('counter responds to a click', () => {
  render(<App />)
  fireEvent.click(screen.getByRole('button', { name: 'Count: 0' }))
  expect(screen.getByRole('button', { name: 'Count: 1' })).toBeTruthy()
})
