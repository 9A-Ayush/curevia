# Medicine & Home Remedies Filter Fix

## Problem
When applying category filters in Medicine Directory and Home Remedies screens, no results were shown.

## Root Cause
The Firestore queries were using `.where('categoryName', isEqualTo: category).orderBy('name')` which requires composite indexes in Firestore. These indexes were missing from the configuration.

## Solution Applied

### 1. Updated Firestore Indexes (`firestore.indexes.json`)
Added two new composite indexes:

```json
{
  "collectionGroup": "medicines",
  "fields": [
    { "fieldPath": "categoryName", "order": "ASCENDING" },
    { "fieldPath": "name", "order": "ASCENDING" }
  ]
},
{
  "collectionGroup": "home_remedies",
  "fields": [
    { "fieldPath": "categoryName", "order": "ASCENDING" },
    { "fieldPath": "title", "order": "ASCENDING" }
  ]
}
```

### 2. Modified Service Methods
Changed the filtering logic to work without indexes by:
- Removing `.orderBy()` from Firestore queries
- Sorting results client-side after fetching

**Medicine Service** (`lib/services/firebase/medicine_service.dart`):
```dart
// Before: .where('categoryName', isEqualTo: category).orderBy('name')
// After: .where('categoryName', isEqualTo: category) + client-side sort
```

**Home Remedies Service** (`lib/services/firebase/home_remedies_service.dart`):
```dart
// Before: .where('categoryName', isEqualTo: category).orderBy('id')
// After: .where('categoryName', isEqualTo: category) + client-side sort
```

### 3. Deployed Indexes
```bash
firebase deploy --only firestore:indexes
```

## Testing
1. Hot restart your Flutter app
2. Navigate to Medicine Directory
3. Select a category filter (e.g., "Pain Relief", "Antibiotics")
4. Verify medicines are displayed
5. Navigate to Home Remedies
6. Select a category filter
7. Verify remedies are displayed

## Benefits
- Category filters now work immediately without waiting for indexes
- Client-side sorting is fast for small-medium datasets
- Indexes are deployed for future optimization
- No breaking changes to UI or user experience
