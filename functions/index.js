const functions = require('firebase-functions');
const admin = require('firebase-admin');
const sgMail = require('@sendgrid/mail');

admin.initializeApp();

// Use config: `firebase functions:config:set sendgrid.key="<SENDGRID_KEY>" sendgrid.from="noreply@yourdomain.com"`
const SENDGRID_KEY = functions.config().sendgrid?.key || process.env.SENDGRID_API_KEY;
const FROM_EMAIL = functions.config().sendgrid?.from || process.env.SENDGRID_FROM || 'noreply@example.com';
if (SENDGRID_KEY) sgMail.setApiKey(SENDGRID_KEY);

exports.sendOrderReceipt = functions.firestore
  .document('orders/{orderId}')
  .onCreate(async (snap, context) => {
    const order = snap.data();
    const orderId = context.params.orderId;

    // Find customer email: prefer Auth record, fallback to users collection
    let email;
    try {
      const userRecord = await admin.auth().getUser(order.customerId);
      email = userRecord.email;
    } catch (e) {
      const udoc = await admin.firestore().collection('users').doc(order.customerId).get();
      if (udoc.exists) email = udoc.data().email;
    }

    if (!email) {
      console.log('No email for order', orderId, order.customerId);
      return null;
    }

    // Build order summary
    const items = order.items || [];
    const itemLines = items.map(i => `- ${i.name} x${i.qty} : ${i.price}`).join('\n');
    const total = order.total || 0;

    const msg = {
      to: email,
      from: FROM_EMAIL,
      subject: `Your order ${orderId} at SimpleShop`,
      text: `Thank you for your order!\n\nOrder ID: ${orderId}\n\nItems:\n${itemLines}\n\nTotal: ${total}`,
      html: `<p>Thank you for your order!</p><p><strong>Order ID:</strong> ${orderId}</p><p><strong>Items:</strong><br/>${items.map(i=>`${i.name} x${i.qty} — ${i.price}`).join('<br/>')}</p><p><strong>Total:</strong> ${total}</p>`
    };

    if (!SENDGRID_KEY) {
      console.log('SendGrid API key not set; skipping email send for order', orderId);
      return null;
    }

    try {
      await sgMail.send(msg);
      console.log('Sent receipt for order', orderId, 'to', email);
    } catch (err) {
      console.error('Failed to send email for order', orderId, err);
    }

    return null;
  });