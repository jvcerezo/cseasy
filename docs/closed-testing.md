# Closed test plan (required: 12+ testers for 14 consecutive days)

Your Play developer account is a personal account created in 2026, so Google requires a closed test with at least 12 opted-in testers for 14 consecutive days before the app can go to production. The requirement applies to each new app.

## Target
- Recruit **15 to 20 testers**, so a few dropouts don't take you below 12.
- Testers must stay opted in for all 14 days. Someone opting out does not restart your clock, but falling below 12 does.
- When you apply for production, Google asks how testers used the app and what you changed. Real usage and real feedback matter, so plan at least one update during the test.

## Where to find testers
1. **Friends and family with Android phones.** Ask them to do one practice round a day. The streak counter gives them a reason to.
2. **CSE reviewee Facebook groups.** Offer free lifetime full access to anyone who tests for 14 days and sends feedback. These are your real users and your best question checkers. Use Play's promo codes for the full-access product to give it to them.
3. **Tester exchange communities** (for example, r/AndroidClosedTesting) to top up the count. Expect little feedback from these.

## Setup steps (Play Console)
1. Create the app: name "CSEasy", default language English (Philippines) or English (US), App, Free.
2. Testing → Closed testing → Create track. Add testers by email list or a Google Group. A Google Group is easier: testers join the group, and you add the group once.
3. Upload the AAB (see `release-checklist.md`), fill in release notes, and roll out to the closed track.
4. Share the opt-in link with testers. Each tester must open the link, accept, and install from Play.
5. Day 1 is the first day you have 12 or more opted-in testers. Mark day 15 on your calendar.

## During the 14 days
- Ask for feedback in one place, such as a Messenger group or Google Form.
- Ship at least one update with fixes from tester feedback, and note what changed for the production application.
- Watch Play Console → Android vitals for crashes.

## After day 14
Apply for production access from the Dashboard. Answer the questions about testers, feedback, and changes concretely. Review usually takes a few days and can take up to about a week. Then publish to production, with a staged rollout if you like.

## Timeline against the March 2027 CSE
- Start the closed test **by mid-November 2026**.
- Apply for production at the start of December.
- Live by mid-December, so the listing has time to rank before the January to March search spike.
