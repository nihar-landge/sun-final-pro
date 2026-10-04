import { describe, expect, test, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import Login from './pages/Login';
import { AuthProvider } from './auth/AuthContext';
import { StatusChip } from './components/StatusChip';

function renderLogin() {
  return render(
    <MemoryRouter initialEntries={['/login']}>
      <AuthProvider>
        <Login />
      </AuthProvider>
    </MemoryRouter>,
  );
}

describe('Login page', () => {
  test('renders the email and password fields', () => {
    renderLogin();
    expect(screen.getByLabelText(/email/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/password/i)).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /sign in/i })).toBeInTheDocument();
  });
});

describe('StatusChip', () => {
  test('shows the status text', () => {
    render(<StatusChip status="IN_PROGRESS" />);
    expect(screen.getByText('IN_PROGRESS')).toBeInTheDocument();
  });
});

describe('api client', () => {
  test('unwrap returns the envelope data', async () => {
    const client = await import('./api/client');
    const fake = { data: { data: { hello: 'world' }, success: true } };
    await expect(client.unwrap(Promise.resolve(fake))).resolves.toEqual({ hello: 'world' });
  });

  test('unwrap surfaces failed envelopes as errors', async () => {
    const client = await import('./api/client');
    const fake = {
      data: { success: false, message: 'nope' },
      response: { data: { message: 'nope' } },
    };
    await expect(client.unwrap(Promise.reject(fake))).rejects.toBeDefined();
  });
});
