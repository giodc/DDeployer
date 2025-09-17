@extends('layouts.app')

@section('title', 'Sites')

@section('content')
<div class="space-y-6">
    <!-- Header -->
    <div class="bg-white overflow-hidden shadow rounded-lg">
        <div class="px-4 py-5 sm:p-6">
            <div class="flex justify-between items-center">
                <div>
                    <h1 class="text-2xl font-bold text-gray-900">
                        <i class="fas fa-globe mr-2 text-blue-600"></i>Sites Management
                    </h1>
                    <p class="mt-1 text-sm text-gray-600">Manage your hosted websites and applications</p>
                </div>
                <a href="{{ route('sites.create') }}" class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700">
                    <i class="fas fa-plus mr-2"></i>Create New Site
                </a>
            </div>
        </div>
    </div>

    <!-- Sites List -->
    <div class="bg-white shadow overflow-hidden sm:rounded-md">
        @if($sites->count() > 0)
            <ul class="divide-y divide-gray-200">
                @foreach($sites as $site)
                    <li>
                        <div class="px-4 py-4 flex items-center justify-between hover:bg-gray-50">
                            <div class="flex items-center">
                                <div class="flex-shrink-0 h-10 w-10">
                                    <div class="h-10 w-10 rounded-full flex items-center justify-center
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
                                    <div class="flex items-center">
                                        <div class="text-sm font-medium text-gray-900">{{ $site->name }}</div>
                                        <span class="ml-2 inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium
                                            @if($site->status === 'running') bg-green-100 text-green-800
                                            @elseif($site->status === 'stopped') bg-yellow-100 text-yellow-800
                                            @elseif($site->status === 'error') bg-red-100 text-red-800
                                            @else bg-gray-100 text-gray-800 @endif">
                                            @if($site->status === 'running')
                                                <i class="fas fa-play mr-1"></i>
                                            @elseif($site->status === 'stopped')
                                                <i class="fas fa-stop mr-1"></i>
                                            @elseif($site->status === 'error')
                                                <i class="fas fa-exclamation-triangle mr-1"></i>
                                            @else
                                                <i class="fas fa-clock mr-1"></i>
                                            @endif
                                            {{ ucfirst($site->status) }}
                                        </span>
                                    </div>
                                    <div class="text-sm text-gray-500">
                                        <span class="capitalize">{{ $site->type }}</span> • 
                                        {{ $site->primary_domain ?? 'No domain configured' }}
                                        @if($site->ssl_enabled)
                                            <i class="fas fa-lock text-green-500 ml-2" title="SSL Enabled"></i>
                                        @endif
                                    </div>
                                    @if(count($site->domains) > 1)
                                        <div class="text-xs text-gray-400 mt-1">
                                            +{{ count($site->domains) - 1 }} more domain(s)
                                        </div>
                                    @endif
                                </div>
                            </div>

                            <div class="flex items-center space-x-2">
                                <!-- Quick Actions -->
                                @if($site->status === 'running')
                                    <form action="{{ route('sites.stop', $site) }}" method="POST" class="inline">
                                        @csrf
                                        <button type="submit" class="text-yellow-600 hover:text-yellow-900" title="Stop Site">
                                            <i class="fas fa-stop"></i>
                                        </button>
                                    </form>
                                @elseif($site->status === 'stopped')
                                    <form action="{{ route('sites.start', $site) }}" method="POST" class="inline">
                                        @csrf
                                        <button type="submit" class="text-green-600 hover:text-green-900" title="Start Site">
                                            <i class="fas fa-play"></i>
                                        </button>
                                    </form>
                                @endif

                                <!-- View Site -->
                                @if($site->primary_domain && $site->status === 'running')
                                    <a href="http{{ $site->ssl_enabled ? 's' : '' }}://{{ $site->primary_domain }}" 
                                       target="_blank" 
                                       class="text-blue-600 hover:text-blue-900" 
                                       title="Visit Site">
                                        <i class="fas fa-external-link-alt"></i>
                                    </a>
                                @endif

                                <!-- Actions Dropdown -->
                                <div class="relative" x-data="{ open: false }">
                                    <button @click="open = !open" class="text-gray-400 hover:text-gray-600">
                                        <i class="fas fa-ellipsis-v"></i>
                                    </button>
                                    <div x-show="open" 
                                         x-cloak
                                         @click.away="open = false"
                                         class="origin-top-right absolute right-0 mt-2 w-48 rounded-md shadow-lg bg-white ring-1 ring-black ring-opacity-5 z-10">
                                        <div class="py-1">
                                            <a href="{{ route('sites.show', $site) }}" class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100">
                                                <i class="fas fa-eye mr-2"></i>View Details
                                            </a>
                                            <a href="{{ route('sites.edit', $site) }}" class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100">
                                                <i class="fas fa-edit mr-2"></i>Edit
                                            </a>
                                            <button onclick="showLogs('{{ $site->id }}')" class="block w-full text-left px-4 py-2 text-sm text-gray-700 hover:bg-gray-100">
                                                <i class="fas fa-file-alt mr-2"></i>View Logs
                                            </button>
                                            <div class="border-t border-gray-100"></div>
                                            <form action="{{ route('sites.destroy', $site) }}" method="POST" onsubmit="return confirm('Are you sure you want to delete this site? This action cannot be undone.')">
                                                @csrf
                                                @method('DELETE')
                                                <button type="submit" class="block w-full text-left px-4 py-2 text-sm text-red-700 hover:bg-red-50">
                                                    <i class="fas fa-trash mr-2"></i>Delete
                                                </button>
                                            </form>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </li>
                @endforeach
            </ul>

            <!-- Pagination -->
            <div class="bg-white px-4 py-3 border-t border-gray-200 sm:px-6">
                {{ $sites->links() }}
            </div>
        @else
            <!-- Empty State -->
            <div class="text-center py-12">
                <i class="fas fa-globe text-6xl text-gray-300 mb-4"></i>
                <h3 class="text-lg font-medium text-gray-900 mb-2">No sites yet</h3>
                <p class="text-gray-500 mb-6">Get started by creating your first website or application.</p>
                <a href="{{ route('sites.create') }}" class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700">
                    <i class="fas fa-plus mr-2"></i>Create Your First Site
                </a>
            </div>
        @endif
    </div>
</div>

<!-- Logs Modal -->
<div id="logsModal" class="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full hidden z-50">
    <div class="relative top-20 mx-auto p-5 border w-11/12 md:w-3/4 lg:w-1/2 shadow-lg rounded-md bg-white">
        <div class="mt-3">
            <div class="flex justify-between items-center mb-4">
                <h3 class="text-lg font-medium text-gray-900">Container Logs</h3>
                <button onclick="closeLogs()" class="text-gray-400 hover:text-gray-600">
                    <i class="fas fa-times"></i>
                </button>
            </div>
            <div class="bg-black text-green-400 p-4 rounded-lg font-mono text-sm max-h-96 overflow-y-auto">
                <pre id="logsContent">Loading logs...</pre>
            </div>
        </div>
    </div>
</div>
@endsection

@push('scripts')
<script>
function showLogs(siteId) {
    document.getElementById('logsModal').classList.remove('hidden');
    document.getElementById('logsContent').textContent = 'Loading logs...';
    
    fetch(`/sites/${siteId}/logs`)
        .then(response => response.json())
        .then(data => {
            document.getElementById('logsContent').textContent = data.logs || 'No logs available';
        })
        .catch(error => {
            document.getElementById('logsContent').textContent = 'Error loading logs: ' + error.message;
        });
}

function closeLogs() {
    document.getElementById('logsModal').classList.add('hidden');
}

// Auto-refresh site statuses every 30 seconds
setInterval(() => {
    location.reload();
}, 30000);
</script>
@endpush
