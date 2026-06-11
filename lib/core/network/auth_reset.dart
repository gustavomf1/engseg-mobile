void Function()? _onForceLogout;

void registerForceLogoutCallback(void Function() cb) => _onForceLogout = cb;

void triggerForceLogout() => _onForceLogout?.call();
