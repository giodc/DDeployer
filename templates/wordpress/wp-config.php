<?php
/**
 * WordPress Configuration - DDeployer Template
 */

// Database settings
define( 'DB_NAME', '{{DB_NAME}}' );
define( 'DB_USER', '{{DB_USER}}' );
define( 'DB_PASSWORD', '{{DB_PASSWORD}}' );
define( 'DB_HOST', 'db' );
define( 'DB_CHARSET', 'utf8mb4' );
define( 'DB_COLLATE', '' );

// Authentication keys and salts
define( 'AUTH_KEY',         '{{AUTH_KEY}}' );
define( 'SECURE_AUTH_KEY',  '{{SECURE_AUTH_KEY}}' );
define( 'LOGGED_IN_KEY',    '{{LOGGED_IN_KEY}}' );
define( 'NONCE_KEY',        '{{NONCE_KEY}}' );
define( 'AUTH_SALT',        '{{AUTH_SALT}}' );
define( 'SECURE_AUTH_SALT', '{{SECURE_AUTH_SALT}}' );
define( 'LOGGED_IN_SALT',   '{{LOGGED_IN_SALT}}' );
define( 'NONCE_SALT',       '{{NONCE_SALT}}' );

// WordPress database table prefix
$table_prefix = 'wp_';

// WordPress debugging
define( 'WP_DEBUG', false );
define( 'WP_DEBUG_LOG', false );
define( 'WP_DEBUG_DISPLAY', false );

// Redis Cache Configuration
define( 'WP_REDIS_HOST', 'redis' );
define( 'WP_REDIS_PORT', 6379 );
define( 'WP_REDIS_DATABASE', 0 );
define( 'WP_CACHE', true );

// Performance optimizations
define( 'AUTOMATIC_UPDATER_DISABLED', true );
define( 'WP_POST_REVISIONS', 3 );
define( 'AUTOSAVE_INTERVAL', 300 );
define( 'WP_CRON_LOCK_TIMEOUT', 120 );

// Security enhancements
define( 'DISALLOW_FILE_EDIT', true );
define( 'FORCE_SSL_ADMIN', {{SSL_ENABLED}} );

// Memory limits
ini_set( 'memory_limit', '256M' );

// Absolute path to WordPress directory
if ( ! defined( 'ABSPATH' ) ) {
    define( 'ABSPATH', __DIR__ . '/' );
}

// Sets up WordPress vars and included files
require_once ABSPATH . 'wp-settings.php';
