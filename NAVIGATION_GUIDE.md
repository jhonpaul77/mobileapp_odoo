# Navigation Guide

## Bottom Navigation - 3 Tabs

### Tab 1: 📊 Dashboard
**Default tab** - Shows database summary & statistics

```
┌─────────────────────────────────────┐
│            DASHBOARD                │
├─────────────────────────────────────┤
│                                     │
│  ┌───────────────────────────────┐  │
│  │  📊 Database Summary          │  │
│  │  Last sync: 5m ago            │  │
│  ├────────────┬──────────────────┤  │
│  │ 📊 1234    │ 📍 45            │  │
│  │ Customers  │ States           │  │
│  ├────────────┼──────────────────┤  │
│  │ 🏙️ 567    │ 📌 8900          │  │
│  │ Cities     │ Districts        │  │
│  ├────────────┴──────────────────┤  │
│  │ [Sync Cust][Sync Locations]   │  │
│  └───────────────────────────────┘  │
│                                     │
│  📋 Quick Info                      │
│  • Full sync strategy               │
│  • Local SQLite cache               │
│  • Auto sync when online            │
│                                     │
│  ❓ How it Works                    │
│  1️⃣ Data Sync - Click to sync      │
│  2️⃣ Local Cache - Instant access   │
│  3️⃣ Offline Ready - No internet OK  │
│                                     │
├─────────────────────────────────────┤
│📊Dashboard│🛍️Penjualan│👤Profile│
└─────────────────────────────────────┘
```

**Features:**
- Stats card showing all counts
- Last sync time
- Quick sync buttons
- Info about the system
- Usage guide

**Interactions:**
- Click "Sync Customers" → Sync all customers
- Click "Sync Locations" → Sync states, cities, districts
- See updated counts after sync

---

### Tab 2: 🛍️ Penjualan
**Sales transactions** - Original Penjualan page

```
┌─────────────────────────────────────┐
│           PENJUALAN                 │
├─────────────────────────────────────┤
│                                     │
│  ⚡ Quick Actions                  │
│  [Transaksi Baru][Daftar Transaksi]│
│                                     │
│  📊 Menu Penjualan                  │
│  [Transaksi][Customer][Produk][...] │
│                                     │
│  📜 Transaksi Terbaru               │
│  • Trans #001                       │
│  • Trans #002                       │
│  • Trans #003                       │
│                                     │
├─────────────────────────────────────┤
│📊Dashboard│🛍️Penjualan│👤Profile│
└─────────────────────────────────────┘
```

**Features:**
- Quick action buttons
- Menu cards
- Recent transactions list

**Interactions:**
- Click menu items to navigate
- Create new transactions
- View transaction details

---

### Tab 3: 👤 Profile
**User settings** - Settings & profile info

```
┌─────────────────────────────────────┐
│            PROFILE                  │
├─────────────────────────────────────┤
│                                     │
│  👤 Profile Information             │
│  Name: [User Name]                  │
│  Email: [user@example.com]          │
│  Role: [Admin/User]                 │
│                                     │
│  ⚙️ Settings                        │
│  • Dark Mode Toggle                 │
│  • Language                         │
│  • Notifications                    │
│  • Data Storage                     │
│                                     │
│  🔗 Server Settings                 │
│  • Database: demotest               │
│  • Server: demoerp.riztastore.id    │
│  • API Key: [***]                   │
│                                     │
│  📱 About                           │
│  Version: 1.0.0                     │
│  [Check Updates]                    │
│                                     │
│  [Sign Out]                         │
│                                     │
├─────────────────────────────────────┤
│📊Dashboard│🛍️Penjualan│👤Profile│
└─────────────────────────────────────┘
```

**Features:**
- User info display
- Settings management
- Server configuration
- Sign out option

---

## Page Transitions

### Flow Diagram

```
Login Page
    ↓
HomePage (3 Tabs)
├── Dashboard
│   ├── Sync Customers (dialog + progress)
│   ├── Sync Locations (dialog + progress)
│   └── Quick info
│
├── Penjualan
│   ├── Quick Actions
│   │   ├── → TransactionCreatePage
│   │   └── → SalesOrderListPage
│   ├── Menu Cards
│   │   ├── → TransactionList
│   │   ├── → CustomerList
│   │   ├── → ProductList
│   │   └── → ...
│   └── Recent Transactions
│       └── → SalesOrderDetail
│
└── Profile
    ├── Settings
    ├── Server Config
    ├── About
    └── Sign Out → LoginPage
```

---

## Detailed Navigation from Dashboard

### Dashboard → Sync Operations

**Sync Customers:**
1. User at Dashboard tab
2. Click "Sync Customers" button
3. Confirmation dialog appears
   - Title: "Sync Customers?"
   - Message: "This will sync all customers from the server..."
   - Buttons: [Cancel] [Sync]
4. If Sync clicked:
   - Progress toast shows: "Syncing customers..."
   - Sync runs in background
   - After complete: Success message shows count
5. Dashboard stats updated automatically

**Sync Locations:**
1. User at Dashboard tab
2. Click "Sync Locations" button
3. Confirmation dialog appears
   - Title: "Sync Locations?"
   - Message: "This will sync all states, cities, and districts..."
   - Buttons: [Cancel] [Sync]
4. If Sync clicked:
   - Progress toast shows: "Syncing locations..."
   - Sync runs in background
   - After complete: Success message shows counts
5. Dashboard stats updated automatically

---

## Navigation from Customer List

### Customer List → Location Sync

**Quick Refresh:**
1. User at Customer List page
2. See location stats bar: "📍 45 | 🏙️ 567 | 📌 8900"
3. Click "Refresh" button
4. Locations synced silently
5. Updated counts shown

**Menu Sync:**
1. User at Customer List page
2. Click menu (⋮) in AppBar
3. Options appear:
   - Sync Customers
   - Sync Locations
4. Select "Sync Locations"
5. Same flow as above

---

## Tab Switching Animation

```
User swipes or taps bottom menu

Dashboard ──(fade)──> Penjualan ──(fade)──> Profile
         <──(fade)──        <──(fade)──
```

All page transitions use 300ms fade animation for smooth UX.

---

## Quick Actions from Dashboard

From Dashboard, users can:

1. **Sync All Data**
   - Click "Sync Customers"
   - Click "Sync Locations"
   - See results in real-time

2. **Navigate to Features**
   - Can use Penjualan tab to access transactions
   - Can use Profile tab to manage settings
   - Can swipe/tap to switch tabs

3. **Monitor Status**
   - See current customer count
   - See current location counts
   - See last sync time
   - Know if updates are pending

---

## Error Handling

If errors occur:

```
User performs action
    ↓
Error occurs
    ↓
Error toast shown
- "Sync failed: [Error details]"
- Red background for visibility
    ↓
User can:
- Retry immediately
- Check connection
- Try again later
```

---

## Keyboard & Touch

### Touch Gestures
- **Tab tap**: Switch between tabs (instant)
- **Button tap**: Trigger actions (immediate feedback)
- **Swipe horizontal**: Slide between tabs
- **Scroll**: Scroll within pages

### Long Press
- No long press actions currently
- Future: Could add for quick actions

---

## Accessibility

All tabs and buttons:
- ✅ Have descriptive labels
- ✅ Have proper icons
- ✅ Have touch targets ≥ 48x48dp
- ✅ Have proper color contrast
- ✅ Work with screen readers

---

## Responsive Design

### Phone (small screen)
```
Full-width tabs, full-width content
```

### Tablet (large screen)
```
Tabs centered, content padded
```

### Landscape
```
Tabs remain at bottom
Content adjusts width
```

---

## Status Indicators

### Dashboard
- ✅ All stats visible at a glance
- ⏳ Syncing state shows progress
- ✅ Success state shows updated counts
- ❌ Error state shows message

### Penjualan
- ✅ Normal operation
- ❌ Any errors show in respective screens

### Profile
- ✅ All settings visible
- ⚙️ Settings being saved show indicator
- ✅ Saved successfully

---

## Summary

Users have 3 clear entry points:

1. **📊 Dashboard** - Database overview & quick sync
2. **🛍️ Penjualan** - Sales operations
3. **👤 Profile** - Settings & account

All interconnected with smooth animations and clear navigation paths.
