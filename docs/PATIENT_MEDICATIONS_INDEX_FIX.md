# Patient Medications Index Fix

## Issue
Firestore query for patient medications was failing with a missing index error:

```
W/Firestore: Listen for Query(target=Query(patient_medications where patientId==pdsDFGlOtVhZY990h6fzj9zQmeH3 and isActive==true order by -createdAt, -__name__);limitType=LIMIT_TO_FIRST) failed: Status{code=FAILED_PRECONDITION, description=The query requires an index.
```

## Analysis
The error message indicates a query with:
- `patientId` filter
- `isActive` filter  
- `createdAt` descending order

However, the main medications query in `SecurePatientDataService.getPatientMedicationsStream()` uses:
```dart
.where('patientId', isEqualTo: patientId)
.where('isActive', isEqualTo: true)
.orderBy('startDate', descending: true)  // Uses startDate, not createdAt
```

## Possible Causes
1. **Different Query Path**: There might be another query or fallback mechanism using `createdAt`
2. **Combined Stream**: The `_createCombinedPatientDataStream` method has a medications query without explicit ordering
3. **Default Ordering**: Firestore might be applying a default `createdAt` ordering in some cases

## Solution Applied
Added a composite index to cover the error pattern:

```json
{
  "collectionGroup": "patient_medications",
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

This is in addition to the existing index:
```json
{
  "collectionGroup": "patient_medications",
  "queryScope": "COLLECTION",
  "fields": [
    {
      "fieldPath": "patientId", 
      "order": "ASCENDING"
    },
    {
      "fieldPath": "isActive",
      "order": "ASCENDING"
    },
    {
      "fieldPath": "startDate",
      "order": "DESCENDING"
    }
  ]
}
```

## Deployment Status
✅ **DEPLOYED**: Updated indexes deployed successfully
```bash
firebase deploy --only firestore:indexes
```

## Next Steps
1. **Test the App**: Run the app and check if the medications error persists
2. **Monitor Logs**: Watch for any remaining index errors
3. **Verify Data**: Check that medications tab shows real data instead of "No data"

## Related Indexes
Current indexes now support:
- ✅ Patient allergies (by severity and createdAt)
- ✅ Patient medications (by startDate and createdAt patterns)
- ✅ Patient vitals (by recordedAt)
- ✅ Doctor access logs (by accessTime)
- ✅ Medical documents (by status and uploadedAt)

## Testing Recommendations
1. Use the debug screen "Add Sample Medical Data" button
2. Navigate to the secure patient medical viewer
3. Check the medications tab for real data
4. Monitor console for any remaining Firestore errors