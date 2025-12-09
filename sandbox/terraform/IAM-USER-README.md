# Automatic IAM User Creation for Student Accounts

## What Gets Created

Every new AWS account automatically gets:

1. **IAM User:** `student`
2. **Initial Password:** `Welcome@2025`
3. **Access Level:** AdministratorAccess (full permissions)
4. **Console Access:** Enabled
5. **Programmatic Access:** Access keys created
6. **Password Policy:** Must change password on first login

## Student Login Instructions

Share these details with students:

```
Account ID: [Account ID from output]
Login URL: https://[ACCOUNT_ID].signin.aws.amazon.com/console

Username: student
Password: Welcome@2025

⚠️ You will be required to change your password on first login
```

## How It Works

### During Account Creation

```
Account Created by AFT
    ↓
Account becomes ACTIVE
    ↓
AFT Customizations Pipeline runs
    ↓
Terraform creates IAM user in account
    ↓
User credentials available in pipeline logs
```

### Where to Find Credentials

**Option 1: CodePipeline Logs**
1. Go to: https://ap-south-1.console.aws.amazon.com/codesuite/codepipeline/pipelines/ct-aft-account-provisioning-customizations/view
2. Click on the execution
3. Click "terraform-apply" stage
4. View logs
5. Look for "student_credentials" output

**Option 2: Directly in Account**
1. Assume role into the account
2. Go to IAM → Users
3. See "student" user
4. Password stored in SSM Parameter: `/aft/iam-user/initial-password`

## Customization Options

### Change Default Password

Edit `iam-user.tf`, line with `value = "Welcome@2025"`:

```terraform
resource "aws_ssm_parameter" "user_password" {
  value = "YourNewPassword@2025"  # Change this
}
```

### Change Username

Edit `iam-user.tf`, line with `name = "student"`:

```terraform
resource "aws_iam_user" "console_user" {
  name = "batch14-student"  # Change this
}
```

### Change Permissions

Edit `iam-user.tf`, policy attachment:

```terraform
resource "aws_iam_user_policy_attachment" "admin_access" {
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"  # Change this
}
```

Available policies:
- `AdministratorAccess` - Full access (current)
- `PowerUserAccess` - All except IAM management
- `ReadOnlyAccess` - Read-only access
- Custom policy ARN

### Disable Access Keys

If students don't need CLI/SDK access, remove this block from `iam-user.tf`:

```terraform
resource "aws_iam_access_key" "console_user_key" {
  user = aws_iam_user.console_user.name
}
```

### Disable Password Change Requirement

Edit `iam-user.tf`:

```terraform
resource "aws_iam_user_login_profile" "console_user_login" {
  password_reset_required = false  # Change to false
}
```

## For Existing Accounts

To add IAM users to already-created accounts:

**Option 1: Manual**
1. Switch role to each account
2. Go to IAM → Users → Add User
3. Create "student" user
4. Set password
5. Attach AdministratorAccess policy

**Option 2: Automated Script**
Would need to create a script to iterate through all accounts and create users.

## Security Considerations

**Current Setup:**
- ✅ Strong initial password required
- ✅ Force password change on first login
- ✅ AdministratorAccess (students can learn freely)
- ⚠️ All students share same initial password (must change immediately)

**For Production:**
- Consider unique passwords per account
- Enable MFA requirement
- Use more restrictive permissions
- Rotate access keys regularly
- Monitor login activity

## Student Handoff Template

Use this template to share with students:

```
═══════════════════════════════════════════════════════════════
Welcome to Your AWS Account!
═══════════════════════════════════════════════════════════════

Your AWS Account Details:
- Account Name: [Account Name]
- Account ID: [Account ID]

Login Information:
- URL: https://[ACCOUNT_ID].signin.aws.amazon.com/console
- Username: student
- Password: Welcome@2025

⚠️ IMPORTANT:
1. You MUST change your password on first login
2. Your account has a $200/month spending limit
3. You'll receive email alerts at 80%, 90%, 100% of budget
4. Account restricted to small instances (t2/t3 micro/small only)
5. Expensive services (SageMaker, Redshift) are blocked

Getting Started:
1. Login using the URL above
2. Create a new secure password
3. Start exploring AWS services!
4. Monitor your costs: Billing Dashboard

Need Help?
- Check AWS documentation: https://docs.aws.amazon.com/
- Contact: ravish.snkhyn@gmail.com

═══════════════════════════════════════════════════════════════
```

## Troubleshooting

### Password Not Working
- Check if password reset was required
- Verify account ID is correct in login URL
- User might have already changed password

### User Not Found
- Check if customizations pipeline succeeded
- Verify account age (user created 5-10 min after account)
- Check CloudWatch logs for errors

### No Administrator Access
- Verify policy attachment in account
- Check IAM → Users → student → Permissions

## Testing

After pushing changes, test by:

1. Creating a new test account via workflow
2. Wait 15-20 minutes
3. Get account ID from Organizations
4. Try login: `https://ACCOUNT_ID.signin.aws.amazon.com/console`
5. Username: `student`, Password: `Welcome@2025`
6. Verify forced password change
7. Verify admin access works

## Cost Impact

Creating IAM users adds **NO cost**:
- IAM users: Free
- Access keys: Free
- SSM parameters: First 10,000 free, then $0.05 per parameter/month

Your $200 budget per account remains unchanged.

