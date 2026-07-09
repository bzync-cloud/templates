<script setup>
defineProps({
  framework: {
    type: String,
    required: true,
  },
});
</script>

<template>
  <main style="font-family: system-ui, sans-serif; padding: 4rem;">
    <h1>Laravel Inertia {{ framework }}</h1>
    <p>Your Bzync Cloud starter is running.</p>
  </main>
</template>
