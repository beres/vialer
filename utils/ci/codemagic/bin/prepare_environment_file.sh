set -e # exit on first failed command set
cp .env.example .env
sed -i -e "s/LOGENTRIES_ANDROID_TOKEN=/LOGENTRIES_ANDROID_TOKEN=${LOGENTRIES_ANDROID_TOKEN}/g" .env
sed -i -e "s/LOGENTRIES_IOS_TOKEN=/LOGENTRIES_IOS_TOKEN=${LOGENTRIES_IOS_TOKEN}/g" .env
sed -i -e "s/COMMIT_HASH=/COMMIT_HASH=${FCI_COMMIT}/g" .env
sed -i -e "s|SENTRY_DSN=|SENTRY_DSN=${SENTRY_DSN}|g" .env
sed -i -e "s|SANDBOX=|SANDBOX=${ENABLE_IOS_SANDBOX_PUSH_NOTIFICATIONS}|g" .env
sed -i -e "s|SEGMENT_ANDROID_KEY=|SEGMENT_ANDROID_KEY=${SEGMENT_ANDROID_WRITE_KEY}|g" .env
sed -i -e "s|SEGMENT_IOS_KEY=|SEGMENT_IOS_KEY=${SEGMENT_IOS_WRITE_KEY}|g" .env
sed -i -e "s|FEATURE_FEATURE_ANNOUNCEMENT=|FEATURE_FEATURE_ANNOUNCEMENT=${FEATURE_FEATURE_ANNOUNCEMENT}|g" .env