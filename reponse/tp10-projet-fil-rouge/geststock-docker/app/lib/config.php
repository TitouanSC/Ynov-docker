<?php
// Configuration via environnement / secrets (plus de mots de passe en dur).
function env_or(string $key, string $default = ''): string {
    $v = getenv($key);
    return ($v === false || $v === '') ? $default : $v;
}

function secret_or_env(string $fileEnv, string $plainEnv, string $default = ''): string {
    $file = getenv($fileEnv);
    if ($file && is_readable($file)) {
        return trim(file_get_contents($file));
    }
    return env_or($plainEnv, $default);
}

define('DB_HOST', env_or('DB_HOST', 'db'));
define('DB_NAME', env_or('DB_NAME', 'geststock'));
define('DB_USER', env_or('DB_USER', 'geststock'));
define('DB_PASS', secret_or_env('DB_PASS_FILE', 'DB_PASS', ''));
define('UPLOAD_DIR', env_or('UPLOAD_DIR', '/var/www/uploads/'));
define('LOG_FILE', env_or('LOG_FILE', 'php://stderr'));
define('SMTP_HOST', env_or('SMTP_HOST', 'mailpit'));
define('REPORT_TO', env_or('REPORT_TO', 'direction@shop.example'));
