<script setup>
import { computed } from 'vue'
import { Head, useForm } from '@inertiajs/vue3'

const props = defineProps({
  providers: Array,
  audits: Array
})

// Inertia form helper manages the request state and CSRF automatically
const form = useForm({})

const triggerScan = (id) => {
  form.post(`/launch/providers/${id}/evaluate`, {
    preserveScroll: true,
    onSuccess: () => {
      // Data in 'props.audits' and 'props.providers' is now fresh
      console.log("Assessment complete")
    }
  })
}

const formatTime = (dateString) => {
  return new Date(dateString).toLocaleTimeString([], {
    hour: '2-digit',
    minute: '2-digit'
  })
}
</script>

<template>
  <Head title="Program Assurance Dashboard" />

  <div class="min-h-screen bg-slate-50 p-8">
    <div class="max-w-7xl mx-auto">
      <header class="mb-10">
        <h1 class="text-3xl font-extrabold text-slate-900 tracking-tight">
          Program Assurance Engine
        </h1>
        <p class="text-slate-500 mt-2 font-medium">
          Operational Risk Monitoring • Vue 3 SPA Interface
        </p>
      </header>

      <div class="grid grid-cols-1 lg:grid-cols-3 gap-10">
        <div class="lg:col-span-2 space-y-6">
          <div class="flex items-center justify-between mb-2">
            <h2 class="text-lg font-bold text-slate-800 flex items-center">
              <span class="flex h-3 w-3 mr-3">
                <span class="animate-ping absolute inline-flex h-3 w-3 rounded-full bg-red-400 opacity-75"></span>
                <span class="relative inline-flex rounded-full h-3 w-3 bg-red-500"></span>
              </span>
              Priority Review Queue
            </h2>
          </div>

          <div v-for="provider in providers" :key="provider.id"
               class="bg-white border border-slate-200 rounded-xl p-6 shadow-sm hover:border-indigo-300 transition-all duration-200">
            <div class="flex justify-between items-start">
              <div class="flex-1">
                <h3 class="text-lg font-bold text-slate-900">{{ provider.name }}</h3>
                <p class="text-sm text-slate-500 font-mono">License: {{ provider.license_number }}</p>

                <button
                  @click="triggerScan(provider.id)"
                  :disabled="form.processing"
                  class="mt-4 inline-flex items-center px-3 py-1.5 border border-transparent text-xs font-bold rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none disabled:opacity-50 transition-colors"
                >
                  <svg v-if="form.processing" class="animate-spin -ml-1 mr-2 h-3 w-3 text-white" fill="none" viewBox="0 0 24 24">
                    <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                    <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                  </svg>
                  {{ form.processing ? 'SCANNING...' : 'RE-SCAN NOW' }}
                </button>
              </div>

              <div class="flex flex-col items-end">
                <div class="text-2xl font-black text-red-600">{{ provider.risk_score }}</div>
                <div class="text-[10px] font-bold text-slate-400 uppercase tracking-tighter">Risk Score</div>
              </div>
            </div>

            <div class="mt-5 flex gap-2 flex-wrap">
              <span v-for="flag in provider.risk_flags" :key="flag"
                    class="px-2.5 py-1 rounded-md text-[10px] font-bold uppercase tracking-wide bg-slate-100 text-slate-600 border border-slate-200">
                {{ flag.replace(/_/g, ' ') }}
              </span>
            </div>
          </div>
        </div>

        <div class="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden h-fit">
          <div class="p-6 border-b border-slate-100 bg-slate-50/50">
            <h2 class="text-sm font-black text-slate-900 uppercase tracking-widest text-center">System Heartbeat</h2>
          </div>
          <div class="p-6">
            <div class="space-y-8 relative">
              <div class="absolute left-[15px] top-2 bottom-2 w-0.5 bg-slate-100"></div>

              <div v-for="audit in audits" :key="audit.id" class="flex gap-4 relative">
                <div class="z-10 w-8 h-8 rounded-full bg-white border-2 border-indigo-500 flex items-center justify-center text-[10px] font-black text-indigo-600 shadow-sm">
                  {{ audit.new_score }}
                </div>
                <div class="flex-1 min-w-0">
                  <p class="text-xs font-bold text-slate-800 truncate">{{ audit.provider.name }}</p>
                  <p class="text-[10px] text-slate-400 mt-0.5">
                    {{ formatTime(audit.created_at) }} — {{ audit.changed_by }}
                  </p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
