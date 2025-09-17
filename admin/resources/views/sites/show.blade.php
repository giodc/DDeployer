@extends('layouts.app')

@section('title', $site->name)

@section('content')
<div class="space-y-6">
    <!-- Header -->
    <div class="bg-white overflow-hidden shadow rounded-lg">
        <div class="px-4 py-5 sm:p-6">
            <div class="flex justify-between items-start">
                <div class="flex items-center">
                    <div class="flex-shrink-0 h-12 w-12">
                        <div class="h-12 w-12 rounded-full flex items-center justify-center text-xl
                            @if($site->type === 'wordpress') bg-blue-100
                            @elseif($site->type === 'laravel') bg-red-100
                            @else bg-purple-100 @endif">
                            @if($site->type === 'wordpress')
                                <i class="fab fa-wordpress text-blue-600"></i>
                            @elseif($site->type === 'laravel')
                                <i class="fab fa-laravel text-red-600"></i>
                            @else
                                <i class="fab fa-php text-purple-600"></i>
                            @endif
                        </div>
                    </div>
                    <div class="ml-4">
                        <h1 class="text-2xl font-bold text-gray-900">{{ $site->name }}</h1>
                        <div class="flex items-center mt-1">
                            <span class="capitalize text-sm text-gray-500">{{ $site->type }}</span>
                            <span class="mx-2 text-gray-300">•</span>
                            <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium
                                @if($site->status === 'running') bg-green-100 text-green-800
                                @elseif($site->status === 'stopped') bg-yellow-100 text-yellow-800
                                @elseif($site->status === 'error') bg-red-100 text-red-800
                                @else bg-gray-100 text-gray-800 @endif">
                                {{ ucfirst($site->status) }}
                            </span>
                        </div>
                    </div>
                </div>
                <div class="flex space-x-3">
                    @if($site->status === 'running')
                        <form action="{{ route('sites.stop', $site) }}" method="POST" class="inline">
                            @csrf
                            <button type="submit" class="inline-flex items-center px-3 py-2 border border-transparent text-sm leading-4 font-medium rounded-md text-white bg-yellow-600 hover:bg-yellow-700">
                                <i class="fas fa-stop mr-2"></i>Stop
                            </button>
                        </form>
                    @elseif($site->status === 'stopped')
                        <form action="{{ route('sites.start', $site) }}" method="POST" class="inline">
                            @csrf
                            <button type="submit" class="inline-flex items-center px-3 py-2 border border-transparent text-sm leading-4 font-medium rounded-md text-white bg-green-600 hover:bg-green-700">
                                <i class="fas fa-play mr-2"></i>Start
                            </button>
                        </form>
                    @endif
                    <a href="{{ route('sites.edit', $site) }}" class="inline-flex items-center px-3 py-2 border border-gray-300 text-sm leading-4 font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50">
                        <i class="fas fa-edit mr-2"></i>Edit
                    </a>
                </div>
            </div>
        </div>
    </div>

    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <!-- Site Information -->
        <div class="lg:col-span-2 space-y-6">
            <!-- Domains -->
            <div class="bg-white shadow rounded-lg">
                <div class="px-4 py-5 sm:p-6">
                    <h3 class="text-lg leading-6 font-medium text-gray-900 mb-4">
                        <i class="fas fa-globe mr-2 text-blue-600"></i>Domains
                    </h3>
                    <div class="space-y-3">
                        @foreach($site->domains as $domain)
                            <div class="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                                <div class="flex items-center">
                                    <span class="text-sm font-medium text-gray-900">{{ $domain }}</span>
                                    @if($site->ssl_enabled && !str_contains($domain, 'localhost'))
                                        <i class="fas fa-lock text-green-500 ml-2" title="SSL Enabled"></i>
                                    @endif
                                </div>
                                <div class="flex items-center space-x-2">
                                    @if($site->status === 'running')
                                        <a href="http{{ $site->ssl_enabled && !str_contains($domain, 'localhost') ? 's' : '' }}://{{ $domain }}" 
                                           target="_blank" 
                                           class="text-blue-600 hover:text-blue-800 text-sm">
                                            <i class="fas fa-external-link-alt mr-1"></i>Visit
                                        </a>
                                    @endif
                                </div>
                            </div>
                        @endforeach
                    </div>
                </div>
            </div>

            <!-- Container Status -->
            <div class="bg-white shadow rounded-lg">
                <div class="px-4 py-5 sm:p-6">
                    <h3 class="text-lg leading-6 font-medium text-gray-900 mb-4">
                        <i class="fas fa-server mr-2 text-green-600"></i>Container Status
                    </h3>
                    <div class="bg-black text-green-400 p-4 rounded-lg font-mono text-sm">
                        <pre>{{ $status['output'] ?: 'Container not running' }}</pre>
                    </div>
                    <div class="mt-4 flex space-x-3">
                        <button onclick="refreshStatus()" class="text-sm text-blue-600 hover:text-blue-800">
                            <i class="fas fa-sync-alt mr-1"></i>Refresh Status
                        </button>
                        <button onclick="showLogs()" class="text-sm text-blue-600 hover:text-blue-800">
                            <i class="fas fa-file-alt mr-1"></i>View Logs
                        </button>
                    </div>
                </div>
            </div>

            <!-- Recent Deployments -->
            @if($site->deployments->count() > 0)
                <div class="bg-white shadow rounded-lg">
                    <div class="px-4 py-5 sm:p-6">
                        <h3 class="text-lg leading-6 font-medium text-gray-900 mb-4">
                            <i class="fas fa-rocket mr-2 text-purple-600"></i>Recent Deployments
                        </h3>
                        <div class="space-y-3">
                            @foreach($site->deployments->take(5) as $deployment)
                                <div class="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                                    <div>
                                        <div class="text-sm font-medium text-gray-900">Version {{ $deployment->version }}</div>
                                        <div class="text-xs text-gray-500">{{ $deployment->created_at->diffForHumans() }}</div>
                                    </div>
                                    <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium
                                        @if($deployment->status === 'success') bg-green-100 text-green-800
                                        @elseif($deployment->status === 'failed') bg-red-100 text-red-800
                                        @elseif($deployment->status === 'running') bg-blue-100 text-blue-800
                                        @else bg-gray-100 text-gray-800 @endif">
                                        {{ ucfirst($deployment->status) }}
                                    </span>
                                </div>
                            @endforeach
                        </div>
                    </div>
                </div>
            @endif
        </div>

        <!-- Sidebar -->
        <div class="space-y-6">
            <!-- Site Details -->
            <div class="bg-white shadow rounded-lg">
                <div class="px-4 py-5 sm:p-6">
                    <h3 class="text-lg leading-6 font-medium text-gray-900 mb-4">
                        <i class="fas fa-info-circle mr-2 text-blue-600"></i>Details
                    </h3>
                    <dl class="space-y-3">
                        <div>
                            <dt class="text-sm font-medium text-gray-500">Container Name</dt>
                            <dd class="text-sm text-gray-900 font-mono">{{ $site->container_name }}</dd>
                        </div>
                        <div>
                            <dt class="text-sm font-medium text-gray-500">PHP Version</dt>
                            <dd class="text-sm text-gray-900">{{ $site->php_version }}</dd>
                        </div>
                        <div>
                            <dt class="text-sm font-medium text-gray-500">SSL Enabled</dt>
                            <dd class="text-sm text-gray-900">
                                @if($site->ssl_enabled)
                                    <i class="fas fa-check text-green-500"></i> Yes
                                @else
                                    <i class="fas fa-times text-red-500"></i> No
                                @endif
                            </dd>
                        </div>
                        <div>
                            <dt class="text-sm font-medium text-gray-500">Cache Enabled</dt>
                            <dd class="text-sm text-gray-900">
                                @if($site->cache_enabled)
                                    <i class="fas fa-check text-green-500"></i> Yes
                                @else
                                    <i class="fas fa-times text-red-500"></i> No
                                @endif
                            </dd>
                        </div>
                        <div>
                            <dt class="text-sm font-medium text-gray-500">Created</dt>
                            <dd class="text-sm text-gray-900">{{ $site->created_at->format('M j, Y') }}</dd>
                        </div>
                    </dl>
                </div>
            </div>

            <!-- Database Information -->
            @if($site->database_name)
                <div class="bg-white shadow rounded-lg">
                    <div class="px-4 py-5 sm:p-6">
                        <h3 class="text-lg leading-6 font-medium text-gray-900 mb-4">
                            <i class="fas fa-database mr-2 text-green-600"></i>Database
                        </h3>
                        <dl class="space-y-3">
                            <div>
                                <dt class="text-sm font-medium text-gray-500">Database Name</dt>
                                <dd class="text-sm text-gray-900 font-mono">{{ $site->database_name }}</dd>
                            </div>
                            <div>
                                <dt class="text-sm font-medium text-gray-500">Username</dt>
                                <dd class="text-sm text-gray-900 font-mono">{{ $site->database_user }}</dd>
                            </div>
                        </dl>
                        <div class="mt-4">
                            <a href="/phpmyadmin" target="_blank" class="text-sm text-blue-600 hover:text-blue-800">
                                <i class="fas fa-external-link-alt mr-1"></i>Open phpMyAdmin
                            </a>
                        </div>
                    </div>
                </div>
            @endif

            <!-- Quick Actions -->
            <div class="bg-white shadow rounded-lg">
                <div class="px-4 py-5 sm:p-6">
                    <h3 class="text-lg leading-6 font-medium text-gray-900 mb-4">
                        <i class="fas fa-bolt mr-2 text-yellow-600"></i>Quick Actions
                    </h3>
                    <div class="space-y-2">
                        @if($site->primary_domain && $site->status === 'running')
                            <a href="http{{ $site->ssl_enabled && !str_contains($site->primary_domain, 'localhost') ? 's' : '' }}://{{ $site->primary_domain }}" 
                               target="_blank" 
                               class="block w-full text-center px-3 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50">
                                <i class="fas fa-external-link-alt mr-2"></i>Visit Site
                            </a>
                        @endif
                        <button onclick="showLogs()" class="block w-full text-center px-3 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50">
                            <i class="fas fa-file-alt mr-2"></i>View Logs
                        </button>
                        @if($site->cache_enabled)
                            <a href="/redis" target="_blank" class="block w-full text-center px-3 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50">
                                <i class="fas fa-memory mr-2"></i>Redis Cache
                            </a>
                        @endif
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

<!-- Logs Modal -->
<div id="logsModal" class="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full hidden z-50">
    <div class="relative top-20 mx-auto p-5 border w-11/12 md:w-3/4 lg:w-2/3 shadow-lg rounded-md bg-white">
        <div class="mt-3">
            <div class="flex justify-between items-center mb-4">
                <h3 class="text-lg font-medium text-gray-900">Container Logs - {{ $site->name }}</h3>
                <button onclick="closeLogs()" class="text-gray-400 hover:text-gray-600">
                    <i class="fas fa-times"></i>
                </button>
            </div>
            <div class="bg-black text-green-400 p-4 rounded-lg font-mono text-sm max-h-96 overflow-y-auto">
                <pre id="logsContent">Loading logs...</pre>
            </div>
            <div class="mt-4 flex justify-end">
                <button onclick="refreshLogs()" class="px-4 py-2 text-sm text-blue-600 hover:text-blue-800">
                    <i class="fas fa-sync-alt mr-1"></i>Refresh
                </button>
            </div>
        </div>
    </div>
</div>
@endsection

@push('scripts')
<script>
function showLogs() {
    document.getElementById('logsModal').classList.remove('hidden');
    refreshLogs();
}

function closeLogs() {
    document.getElementById('logsModal').classList.add('hidden');
}

function refreshLogs() {
    document.getElementById('logsContent').textContent = 'Loading logs...';
    
    fetch(`{{ route('sites.logs', $site) }}`)
        .then(response => response.json())
        .then(data => {
            document.getElementById('logsContent').textContent = data.logs || 'No logs available';
        })
        .catch(error => {
            document.getElementById('logsContent').textContent = 'Error loading logs: ' + error.message;
        });
}

function refreshStatus() {
    fetch(`{{ route('api.sites.status', $site) }}`)
        .then(response => response.json())
        .then(data => {
            location.reload();
        })
        .catch(error => {
            console.error('Error refreshing status:', error);
        });
}

// Auto-refresh every 30 seconds
setInterval(refreshStatus, 30000);
</script>
@endpush
