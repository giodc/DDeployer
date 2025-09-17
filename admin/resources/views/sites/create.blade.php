@extends('layouts.app')

@section('title', 'Create New Site')

@section('content')
<div class="max-w-3xl mx-auto">
    <div class="bg-white shadow rounded-lg">
        <div class="px-4 py-5 sm:p-6">
            <div class="mb-6">
                <h1 class="text-2xl font-bold text-gray-900">
                    <i class="fas fa-plus mr-2 text-blue-600"></i>Create New Site
                </h1>
                <p class="mt-1 text-sm text-gray-600">Deploy a new website or application with Docker</p>
            </div>

            <form action="{{ route('sites.store') }}" method="POST" x-data="siteForm()" class="space-y-6">
                @csrf

                <!-- Site Name -->
                <div>
                    <label for="name" class="block text-sm font-medium text-gray-700">Site Name</label>
                    <input type="text" 
                           name="name" 
                           id="name" 
                           value="{{ old('name') }}"
                           x-model="form.name"
                           class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
                           placeholder="my-awesome-site"
                           required>
                    @error('name')
                        <p class="mt-1 text-sm text-red-600">{{ $message }}</p>
                    @enderror
                    <p class="mt-1 text-xs text-gray-500">Used for container naming and identification</p>
                </div>

                <!-- Site Type -->
                <div>
                    <label class="block text-sm font-medium text-gray-700 mb-3">Site Type</label>
                    <div class="grid grid-cols-1 sm:grid-cols-3 gap-4">
                        <div class="relative">
                            <input type="radio" 
                                   name="type" 
                                   id="wordpress" 
                                   value="wordpress" 
                                   x-model="form.type"
                                   class="sr-only peer"
                                   {{ old('type') === 'wordpress' ? 'checked' : '' }}>
                            <label for="wordpress" class="flex flex-col items-center p-4 border-2 border-gray-200 rounded-lg cursor-pointer hover:bg-gray-50 peer-checked:border-blue-500 peer-checked:bg-blue-50">
                                <i class="fab fa-wordpress text-3xl text-blue-600 mb-2"></i>
                                <span class="font-medium">WordPress</span>
                                <span class="text-xs text-gray-500 text-center">Full WordPress with caching</span>
                            </label>
                        </div>
                        <div class="relative">
                            <input type="radio" 
                                   name="type" 
                                   id="laravel" 
                                   value="laravel" 
                                   x-model="form.type"
                                   class="sr-only peer"
                                   {{ old('type') === 'laravel' ? 'checked' : '' }}>
                            <label for="laravel" class="flex flex-col items-center p-4 border-2 border-gray-200 rounded-lg cursor-pointer hover:bg-gray-50 peer-checked:border-red-500 peer-checked:bg-red-50">
                                <i class="fab fa-laravel text-3xl text-red-600 mb-2"></i>
                                <span class="font-medium">Laravel</span>
                                <span class="text-xs text-gray-500 text-center">Laravel with queues</span>
                            </label>
                        </div>
                        <div class="relative">
                            <input type="radio" 
                                   name="type" 
                                   id="php" 
                                   value="php" 
                                   x-model="form.type"
                                   class="sr-only peer"
                                   {{ old('type') === 'php' ? 'checked' : '' }}>
                            <label for="php" class="flex flex-col items-center p-4 border-2 border-gray-200 rounded-lg cursor-pointer hover:bg-gray-50 peer-checked:border-purple-500 peer-checked:bg-purple-50">
                                <i class="fab fa-php text-3xl text-purple-600 mb-2"></i>
                                <span class="font-medium">PHP</span>
                                <span class="text-xs text-gray-500 text-center">Generic PHP application</span>
                            </label>
                        </div>
                    </div>
                    @error('type')
                        <p class="mt-1 text-sm text-red-600">{{ $message }}</p>
                    @enderror
                </div>

                <!-- Domains -->
                <div>
                    <label class="block text-sm font-medium text-gray-700 mb-2">Domains</label>
                    <div x-data="{ domains: {{ json_encode(old('domains', [''])) }} }">
                        <template x-for="(domain, index) in domains" :key="index">
                            <div class="flex items-center mb-2">
                                <input type="text" 
                                       :name="'domains[' + index + ']'" 
                                       x-model="domains[index]"
                                       class="flex-1 border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
                                       placeholder="example.com or site.localhost"
                                       required>
                                <button type="button" 
                                        @click="domains.splice(index, 1)"
                                        x-show="domains.length > 1"
                                        class="ml-2 text-red-600 hover:text-red-800">
                                    <i class="fas fa-trash"></i>
                                </button>
                            </div>
                        </template>
                        <button type="button" 
                                @click="domains.push('')"
                                class="text-sm text-blue-600 hover:text-blue-800">
                            <i class="fas fa-plus mr-1"></i>Add Another Domain
                        </button>
                    </div>
                    @error('domains')
                        <p class="mt-1 text-sm text-red-600">{{ $message }}</p>
                    @enderror
                    <p class="mt-1 text-xs text-gray-500">Use .localhost domains for local development</p>
                </div>

                <!-- PHP Version -->
                <div>
                    <label for="php_version" class="block text-sm font-medium text-gray-700">PHP Version</label>
                    <select name="php_version" 
                            id="php_version" 
                            class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 sm:text-sm">
                        <option value="8.3" {{ old('php_version', '8.3') === '8.3' ? 'selected' : '' }}>PHP 8.3 (Recommended)</option>
                        <option value="8.2" {{ old('php_version') === '8.2' ? 'selected' : '' }}>PHP 8.2</option>
                        <option value="8.1" {{ old('php_version') === '8.1' ? 'selected' : '' }}>PHP 8.1</option>
                    </select>
                    @error('php_version')
                        <p class="mt-1 text-sm text-red-600">{{ $message }}</p>
                    @enderror>
                </div>

                <!-- Database Configuration -->
                <div class="border border-gray-200 rounded-lg p-4">
                    <div class="flex items-center mb-4">
                        <input type="checkbox" 
                               name="create_database" 
                               id="create_database" 
                               value="1"
                               x-model="form.createDatabase"
                               class="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
                               {{ old('create_database') ? 'checked' : '' }}>
                        <label for="create_database" class="ml-2 block text-sm font-medium text-gray-700">
                            Create Database
                        </label>
                    </div>
                    <div x-show="form.createDatabase" class="space-y-4">
                        <div class="bg-blue-50 border border-blue-200 rounded-md p-3">
                            <div class="flex">
                                <i class="fas fa-info-circle text-blue-400 mt-0.5 mr-2"></i>
                                <div class="text-sm text-blue-700">
                                    <p class="font-medium">Database will be automatically configured</p>
                                    <p class="mt-1">A MariaDB database will be created with secure credentials for your site.</p>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Advanced Options -->
                <div class="border border-gray-200 rounded-lg p-4">
                    <h3 class="text-sm font-medium text-gray-700 mb-4">Advanced Options</h3>
                    <div class="space-y-4">
                        <!-- SSL -->
                        <div class="flex items-center">
                            <input type="checkbox" 
                                   name="ssl_enabled" 
                                   id="ssl_enabled" 
                                   value="1"
                                   class="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
                                   {{ old('ssl_enabled') ? 'checked' : '' }}>
                            <label for="ssl_enabled" class="ml-2 block text-sm text-gray-700">
                                Enable SSL (Let's Encrypt)
                                <span class="text-xs text-gray-500 block">Automatic SSL certificates for custom domains</span>
                            </label>
                        </div>

                        <!-- Caching -->
                        <div class="flex items-center">
                            <input type="checkbox" 
                                   name="cache_enabled" 
                                   id="cache_enabled" 
                                   value="1"
                                   class="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
                                   checked
                                   {{ old('cache_enabled', true) ? 'checked' : '' }}>
                            <label for="cache_enabled" class="ml-2 block text-sm text-gray-700">
                                Enable Redis Caching
                                <span class="text-xs text-gray-500 block">Improves performance with Redis cache</span>
                            </label>
                        </div>
                    </div>
                </div>

                <!-- Actions -->
                <div class="flex justify-end space-x-3 pt-6 border-t border-gray-200">
                    <a href="{{ route('sites.index') }}" class="px-4 py-2 border border-gray-300 rounded-md text-sm font-medium text-gray-700 hover:bg-gray-50">
                        Cancel
                    </a>
                    <button type="submit" class="px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500">
                        <i class="fas fa-rocket mr-2"></i>Create Site
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>
@endsection

@push('scripts')
<script>
function siteForm() {
    return {
        form: {
            name: '',
            type: '',
            createDatabase: false
        }
    }
}
</script>
@endpush
