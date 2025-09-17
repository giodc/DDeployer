@extends('layouts.app')

@section('title', 'Dashboard')

@section('content')
<div class="space-y-6">
    <!-- Header -->
    <div class="bg-white overflow-hidden shadow rounded-lg">
        <div class="px-4 py-5 sm:p-6">
            <h1 class="text-2xl font-bold text-gray-900">
                <i class="fas fa-tachometer-alt mr-2 text-blue-600"></i>Dashboard
            </h1>
            <p class="mt-1 text-sm text-gray-600">Welcome to DDeployer - Docker Web Hosting Platform</p>
        </div>
    </div>

    <!-- Stats Cards -->
    <div class="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-4">
        <!-- Total Sites -->
        <div class="bg-white overflow-hidden shadow rounded-lg">
            <div class="p-5">
                <div class="flex items-center">
                    <div class="flex-shrink-0">
                        <i class="fas fa-globe text-2xl text-blue-600"></i>
                    </div>
                    <div class="ml-5 w-0 flex-1">
                        <dl>
                            <dt class="text-sm font-medium text-gray-500 truncate">Total Sites</dt>
                            <dd class="text-lg font-medium text-gray-900">{{ $stats['total_sites'] }}</dd>
                        </dl>
                    </div>
                </div>
            </div>
        </div>

        <!-- Running Sites -->
        <div class="bg-white overflow-hidden shadow rounded-lg">
            <div class="p-5">
                <div class="flex items-center">
                    <div class="flex-shrink-0">
                        <i class="fas fa-play-circle text-2xl text-green-600"></i>
                    </div>
                    <div class="ml-5 w-0 flex-1">
                        <dl>
                            <dt class="text-sm font-medium text-gray-500 truncate">Running</dt>
                            <dd class="text-lg font-medium text-gray-900">{{ $stats['running_sites'] }}</dd>
                        </dl>
                    </div>
                </div>
            </div>
        </div>

        <!-- Stopped Sites -->
        <div class="bg-white overflow-hidden shadow rounded-lg">
            <div class="p-5">
                <div class="flex items-center">
                    <div class="flex-shrink-0">
                        <i class="fas fa-stop-circle text-2xl text-yellow-600"></i>
                    </div>
                    <div class="ml-5 w-0 flex-1">
                        <dl>
                            <dt class="text-sm font-medium text-gray-500 truncate">Stopped</dt>
                            <dd class="text-lg font-medium text-gray-900">{{ $stats['stopped_sites'] }}</dd>
                        </dl>
                    </div>
                </div>
            </div>
        </div>

        <!-- Error Sites -->
        <div class="bg-white overflow-hidden shadow rounded-lg">
            <div class="p-5">
                <div class="flex items-center">
                    <div class="flex-shrink-0">
                        <i class="fas fa-exclamation-circle text-2xl text-red-600"></i>
                    </div>
                    <div class="ml-5 w-0 flex-1">
                        <dl>
                            <dt class="text-sm font-medium text-gray-500 truncate">Errors</dt>
                            <dd class="text-lg font-medium text-gray-900">{{ $stats['error_sites'] }}</dd>
                        </dl>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <!-- Recent Sites -->
        <div class="bg-white shadow rounded-lg">
            <div class="px-4 py-5 sm:p-6">
                <h3 class="text-lg leading-6 font-medium text-gray-900 mb-4">
                    <i class="fas fa-clock mr-2 text-blue-600"></i>Recent Sites
                </h3>
                @if($recentSites->count() > 0)
                    <div class="space-y-3">
                        @foreach($recentSites as $site)
                            <div class="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                                <div class="flex items-center">
                                    <div class="flex-shrink-0">
                                        @if($site->type === 'wordpress')
                                            <i class="fab fa-wordpress text-blue-600"></i>
                                        @elseif($site->type === 'laravel')
                                            <i class="fab fa-laravel text-red-600"></i>
                                        @else
                                            <i class="fab fa-php text-purple-600"></i>
                                        @endif
                                    </div>
                                    <div class="ml-3">
                                        <p class="text-sm font-medium text-gray-900">{{ $site->name }}</p>
                                        <p class="text-xs text-gray-500">{{ $site->primary_domain }}</p>
                                    </div>
                                </div>
                                <div class="flex items-center">
                                    <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium
                                        @if($site->status === 'running') bg-green-100 text-green-800
                                        @elseif($site->status === 'stopped') bg-yellow-100 text-yellow-800
                                        @elseif($site->status === 'error') bg-red-100 text-red-800
                                        @else bg-gray-100 text-gray-800 @endif">
                                        {{ ucfirst($site->status) }}
                                    </span>
                                </div>
                            </div>
                        @endforeach
                    </div>
                    <div class="mt-4">
                        <a href="{{ route('sites.index') }}" class="text-sm text-blue-600 hover:text-blue-500">
                            View all sites <i class="fas fa-arrow-right ml-1"></i>
                        </a>
                    </div>
                @else
                    <div class="text-center py-6">
                        <i class="fas fa-globe text-4xl text-gray-300 mb-2"></i>
                        <p class="text-gray-500">No sites created yet</p>
                        <a href="{{ route('sites.create') }}" class="mt-2 inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700">
                            <i class="fas fa-plus mr-2"></i>Create First Site
                        </a>
                    </div>
                @endif
            </div>
        </div>

        <!-- System Information -->
        <div class="bg-white shadow rounded-lg">
            <div class="px-4 py-5 sm:p-6">
                <h3 class="text-lg leading-6 font-medium text-gray-900 mb-4">
                    <i class="fas fa-server mr-2 text-green-600"></i>System Information
                </h3>
                <div class="space-y-4">
                    @if(isset($systemInfo['docker_version']))
                        <div class="flex justify-between">
                            <span class="text-sm text-gray-600">Docker Version:</span>
                            <span class="text-sm font-medium">{{ $systemInfo['docker_version'] }}</span>
                        </div>
                    @endif

                    @if(isset($systemInfo['memory']))
                        <div>
                            <div class="flex justify-between mb-1">
                                <span class="text-sm text-gray-600">Memory Usage:</span>
                                <span class="text-sm font-medium">{{ $systemInfo['memory']['used'] }}MB / {{ $systemInfo['memory']['total'] }}MB</span>
                            </div>
                            <div class="w-full bg-gray-200 rounded-full h-2">
                                <div class="bg-blue-600 h-2 rounded-full" style="width: {{ $systemInfo['memory']['percentage'] }}%"></div>
                            </div>
                        </div>
                    @endif

                    @if(isset($systemInfo['disk']))
                        <div>
                            <div class="flex justify-between mb-1">
                                <span class="text-sm text-gray-600">Disk Usage:</span>
                                <span class="text-sm font-medium">{{ $systemInfo['disk']['used'] }}GB / {{ $systemInfo['disk']['total'] }}GB</span>
                            </div>
                            <div class="w-full bg-gray-200 rounded-full h-2">
                                <div class="bg-green-600 h-2 rounded-full" style="width: {{ $systemInfo['disk']['percentage'] }}%"></div>
                            </div>
                        </div>
                    @endif

                    @if(isset($systemInfo['load_average']))
                        <div class="flex justify-between">
                            <span class="text-sm text-gray-600">Load Average:</span>
                            <span class="text-sm font-medium">{{ trim($systemInfo['load_average']) }}</span>
                        </div>
                    @endif
                </div>
            </div>
        </div>
    </div>

    <!-- Quick Actions -->
    <div class="bg-white shadow rounded-lg">
        <div class="px-4 py-5 sm:p-6">
            <h3 class="text-lg leading-6 font-medium text-gray-900 mb-4">
                <i class="fas fa-bolt mr-2 text-yellow-600"></i>Quick Actions
            </h3>
            <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
                <a href="{{ route('sites.create') }}" class="inline-flex items-center justify-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700">
                    <i class="fas fa-plus mr-2"></i>Create Site
                </a>
                <a href="{{ route('sites.index') }}" class="inline-flex items-center justify-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50">
                    <i class="fas fa-list mr-2"></i>View All Sites
                </a>
                <a href="/phpmyadmin" target="_blank" class="inline-flex items-center justify-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50">
                    <i class="fas fa-database mr-2"></i>phpMyAdmin
                </a>
                <a href="/traefik" target="_blank" class="inline-flex items-center justify-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50">
                    <i class="fas fa-network-wired mr-2"></i>Traefik Dashboard
                </a>
            </div>
        </div>
    </div>
</div>
@endsection
