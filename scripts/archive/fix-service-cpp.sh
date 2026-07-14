#!/bin/bash
# Fix service.cpp - add BlueStacks permissive skip
cd ~/aosp16/system/core/init

# Revert to clean state
git checkout -- service.cpp

# Fix 1: Add permissive check at start of ComputeContextFromExecutable
# Insert after the opening brace and first comment
sed -i '/^static Result<std::string> ComputeContextFromExecutable/,/std::string computed_context;/{/std::string computed_context;/a\
    // BlueStacks(baklava bringup): permissive skip\
    if (!is_selinux_enabled() || security_getenforce() == 0) {\
        return "skip";\
    }
}' service.cpp

# Fix 2: Change return Error() to LOG(WARNING) + add return "skip" for domain transition
sed -i '/return Error() << "File " << service_path << "(labeled \\"" << filecon.get()/,/"denials possible.";/{s/return Error()/LOG(WARNING)/}' service.cpp
sed -i '/"denials possible.";/,/^    }/{/"denials possible.";/a\
        return "skip";
}' service.cpp

echo "service.cpp fixed"
grep -A5 "permissive skip\|return \"skip\"" service.cpp | head -15
