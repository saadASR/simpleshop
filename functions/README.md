Setup & deploy instructions for the order email Cloud Function

1) Install dependencies & tools (locally):
   - npm install -g firebase-tools
   - cd functions
   - npm install

2) Configure SendGrid (recommended):
   - Create a SendGrid account and get an API key (or use another email provider).
   - Set the key in Firebase functions config (recommended):
     firebase functions:config:set sendgrid.key="YOUR_SENDGRID_KEY" sendgrid.from="no-reply@yourdomain.com"
     (You can also set env var SENDGRID_API_KEY and SENDGRID_FROM locally.)

3) Deploy functions:
   - From the project root: firebase deploy --only functions

4) Notes & security:
   - The function runs on order creation and tries to lookup the customer's email via Firebase Auth; if not found it checks `users/{uid}`.
   - Keep your email API key secret (use `firebase functions:config:set`).
   - If you prefer not to use SendGrid, replace the send code with your provider's SDK.

5) Testing:
   - Create an order via the app.
   - Check the function logs: firebase functions:log or in the Firebase Console → Functions → Logs.
