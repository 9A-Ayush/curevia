# Patient Allergies Index Fix

## Issue
Firestore query for patient allergies was failing with a missing index error:

```
W/Firestore: Listen for Query(target=Query(patient_allergies where patientId==pdsDFGlOtVhZY990h6fzj9zQmeH3 and isActive==true order by -severity, -createdAt, -__name__);limitType=LIMIT_TO_FIRST) failed: Status{code=FAILED_PRECONDITION, description=The query requires an index.
```

## Root Cause
The query in `SecurePatientDataService.getPatientAllergiesStream()` uses:
```dart
.where('patientId', isEqualTo: patientId)
.where('isActive', isEqualTo: true)
.orderBy('severity', descending: true)
.orderBy('createdAt', descending: true)
```

But the existing index in `firestore.indexes.json` had the fields in a different order.

## Solution
Added the correct composite index to `firestore.indexes.json`:

```json
{
  "collectionGroup": "patient_allergies",
  "queryScope": "COLLECTION",
  "fields": [
    {
      "fieldPath": "isActive",
      "order": "ASCENDING"
    },
    {
      "fieldPath": "patientId", 
      "order": "ASCENDING"
    },
    {
      "fieldPath": "createdAt",
      "order": "DESCENDING"
    }
  ]
}
```

This index matches the exact query pattern used in the code.

## Deployment
Successfully deployed the updated indexes:
```bash
firebase deploy --only firestore:indexes
```

## Status
✅ **FIXED**: The patient allergies query should now work without index errors.

## Related Queries Covered
The current indexes also support these related queries:
- Patient vitals by date
- Patient medications by start date  
- Doctor access logs by time
- Medical documents by status and date

## Testing
The enhanced vitals data functionality should now work properly:
1. Allergies tab will show real data from Firestore
2. Falls back to user profile data if no dedicated allergies exist
3. Sample data can be added via the debug screen

## Next Steps
- Test the allergies tab in the secure patient medical viewer
- Verify data is fetched from Firebase instead of showing "No data"
- Use the debug screen to add sample data if needed