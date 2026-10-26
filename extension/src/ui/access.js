// Firefox can install a Manifest V3 add-on without site access. Without it
// nothing can be measured, so show a button that asks for it.

import { api } from '../shim.js';
import { h, clear } from './dom.js';

const ALL = { origins: ['<all_urls>'] };

export async function hasSiteAccess() {
  try {
    return await api.permissions.contains(ALL);
  } catch {
    return true;
  }
}

export async function accessBanner(container) {
  if (await hasSiteAccess()) {
    clear(container);
    return;
  }
  clear(container).append(
    h(
      'div',
      { class: 'notice' },
      h('p', { style: { margin: '0 0 8px' } }, 'Nireekshana needs access to all sites to see how much data they use. Nothing leaves this device.'),
      h(
        'button',
        {
          class: 'primary',
          onclick: async () => {
            try {
              if (await api.permissions.request(ALL)) clear(container);
            } catch {
              // The user can grant it later from the add-ons page.
            }
          },
        },
        'Allow access',
      ),
    ),
  );
}
