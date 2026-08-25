<template>
  <div class="mission-validator">
    <div class="validator-header">
      <h3>🔍 Mission Validation</h3>
      <div class="validator-controls">
        <button 
          @click="runValidation" 
          :disabled="validating"
          class="btn-validate"
        >
          {{ validating ? 'Validating...' : 'Validate Mission' }}
        </button>
        <label class="auto-validate-toggle">
          <input 
            type="checkbox" 
            v-model="autoValidate"
            @change="toggleAutoValidate"
          >
          Auto-Validate
        </label>
      </div>
    </div>

    <!-- Validation Summary -->
    <div v-if="summary" class="validation-summary">
      <div class="summary-score" :class="scoreClass">
        <span class="score-value">{{ summary.score }}%</span>
        <span class="score-label">Mission Score</span>
      </div>
      
      <div class="summary-stats">
        <div class="stat passed">
          <span class="stat-count">{{ summary.passed }}</span>
          <span class="stat-label">Passed</span>
        </div>
        <div class="stat errors">
          <span class="stat-count">{{ summary.errors }}</span>
          <span class="stat-label">Errors</span>
        </div>
        <div class="stat warnings">
          <span class="stat-count">{{ summary.warnings }}</span>
          <span class="stat-label">Warnings</span>
        </div>
        <div class="stat info">
          <span class="stat-count">{{ summary.info }}</span>
          <span class="stat-label">Info</span>
        </div>
      </div>
    </div>

    <!-- Validation Results -->
    <div class="validation-results">
      <!-- Errors -->
      <div v-if="results?.errors?.length > 0" class="result-section errors">
        <div class="result-header" @click="toggleSection('errors')">
          <span class="expand-icon">{{ expandedSections.errors ? '▼' : '▶' }}</span>
          <h4>❌ Errors ({{ results.errors.length }})</h4>
        </div>
        <div v-show="expandedSections.errors" class="result-items">
          <div 
            v-for="(error, index) in results.errors" 
            :key="index"
            class="result-item"
          >
            <div class="item-header">
              <span class="item-name">{{ error.name }}</span>
              <span class="item-rule">{{ error.ruleId }}</span>
            </div>
            <div class="item-details">{{ error.details }}</div>
            <div v-if="error.suggestion" class="item-suggestion">
              💡 {{ error.suggestion }}
            </div>
          </div>
        </div>
      </div>

      <!-- Warnings -->
      <div v-if="results?.warnings?.length > 0" class="result-section warnings">
        <div class="result-header" @click="toggleSection('warnings')">
          <span class="expand-icon">{{ expandedSections.warnings ? '▼' : '▶' }}</span>
          <h4>⚠️ Warnings ({{ results.warnings.length }})</h4>
        </div>
        <div v-show="expandedSections.warnings" class="result-items">
          <div 
            v-for="(warning, index) in results.warnings" 
            :key="index"
            class="result-item"
          >
            <div class="item-header">
              <span class="item-name">{{ warning.name }}</span>
              <span class="item-rule">{{ warning.ruleId }}</span>
            </div>
            <div class="item-details">{{ warning.details }}</div>
            <div v-if="warning.suggestion" class="item-suggestion">
              💡 {{ warning.suggestion }}
            </div>
          </div>
        </div>
      </div>

      <!-- Info -->
      <div v-if="results?.info?.length > 0" class="result-section info">
        <div class="result-header" @click="toggleSection('info')">
          <span class="expand-icon">{{ expandedSections.info ? '▼' : '▶' }}</span>
          <h4>ℹ️ Information ({{ results.info.length }})</h4>
        </div>
        <div v-show="expandedSections.info" class="result-items">
          <div 
            v-for="(item, index) in results.info" 
            :key="index"
            class="result-item"
          >
            <div class="item-header">
              <span class="item-name">{{ item.name }}</span>
              <span class="item-rule">{{ item.ruleId }}</span>
            </div>
            <div class="item-details">{{ item.details }}</div>
          </div>
        </div>
      </div>

      <!-- Passed -->
      <div v-if="results?.passed?.length > 0" class="result-section passed">
        <div class="result-header" @click="toggleSection('passed')">
          <span class="expand-icon">{{ expandedSections.passed ? '▼' : '▶' }}</span>
          <h4>✅ Passed ({{ results.passed.length }})</h4>
        </div>
        <div v-show="expandedSections.passed" class="result-items">
          <div 
            v-for="(item, index) in results.passed" 
            :key="index"
            class="result-item passed"
          >
            <span class="item-name">{{ item.name }}</span>
          </div>
        </div>
      </div>

      <!-- No Results -->
      <div v-if="!results" class="no-results">
        <p>Click "Validate Mission" to check your mission against the checklist</p>
      </div>
    </div>

    <!-- Export Button -->
    <div v-if="results" class="validator-footer">
      <button @click="exportResults" class="btn-export">
        📄 Export Results
      </button>
    </div>
  </div>
</template>

<script>
import { ref, computed, reactive } from 'vue'

export default {
  name: 'MissionValidator',
  props: {
    validator: {
      type: Object,
      required: true
    },
    missionData: {
      type: Object,
      default: null
    }
  },

  setup(props, { emit }) {
    const validating = ref(false)
    const autoValidate = ref(true)
    const results = ref(null)
    const summary = ref(null)
    const expandedSections = reactive({
      errors: true,
      warnings: true,
      info: false,
      passed: false
    })

    const scoreClass = computed(() => {
      if (!summary.value) return ''
      if (summary.value.score >= 90) return 'excellent'
      if (summary.value.score >= 70) return 'good'
      if (summary.value.score >= 50) return 'fair'
      return 'poor'
    })

    const runValidation = async () => {
      validating.value = true
      
      try {
        const validationResults = await props.validator.validate()
        results.value = validationResults
        
        // Calculate summary
        const total = (validationResults.passed?.length || 0) +
                     (validationResults.errors?.length || 0) +
                     (validationResults.warnings?.length || 0) +
                     (validationResults.info?.length || 0)
        
        const score = total > 0 
          ? Math.round(((validationResults.passed?.length || 0) / total) * 100)
          : 0
        
        summary.value = {
          score,
          passed: validationResults.passed?.length || 0,
          errors: validationResults.errors?.length || 0,
          warnings: validationResults.warnings?.length || 0,
          info: validationResults.info?.length || 0
        }

        emit('validated', validationResults)
      } catch (error) {
        console.error('Validation failed:', error)
        emit('validation-error', error)
      } finally {
        validating.value = false
      }
    }

    const toggleAutoValidate = () => {
      props.validator.setAutoValidate(autoValidate.value)
    }

    const toggleSection = (section) => {
      expandedSections[section] = !expandedSections[section]
    }

    const exportResults = () => {
      // Request export from parent/main process
      emit('export-request', results.value)
    }

    // Auto-validate on mount if enabled
    if (autoValidate.value && props.missionData) {
      runValidation()
    }

    return {
      validating,
      autoValidate,
      results,
      summary,
      scoreClass,
      expandedSections,
      runValidation,
      toggleAutoValidate,
      toggleSection,
      exportResults
    }
  }
}
</script>

<style scoped>
.mission-validator {
  background: #1e1e1e;
  border-radius: 8px;
  padding: 16px;
  color: #e0e0e0;
}

.validator-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
  padding-bottom: 16px;
  border-bottom: 1px solid #333;
}

.validator-header h3 {
  margin: 0;
  font-size: 18px;
  font-weight: 600;
}

.validator-controls {
  display: flex;
  gap: 12px;
  align-items: center;
}

.btn-validate {
  background: #4CAF50;
  color: white;
  border: none;
  padding: 8px 16px;
  border-radius: 4px;
  cursor: pointer;
  font-weight: 500;
  transition: background 0.2s;
}

.btn-validate:hover:not(:disabled) {
  background: #45a049;
}

.btn-validate:disabled {
  background: #666;
  cursor: not-allowed;
}

.auto-validate-toggle {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 14px;
  cursor: pointer;
}

.auto-validate-toggle input {
  cursor: pointer;
}

/* Summary */
.validation-summary {
  background: #2a2a2a;
  border-radius: 8px;
  padding: 16px;
  margin-bottom: 16px;
}

.summary-score {
  text-align: center;
  padding: 12px;
  border-radius: 6px;
  margin-bottom: 12px;
}

.summary-score.excellent {
  background: linear-gradient(135deg, #4CAF50, #2E7D32);
}

.summary-score.good {
  background: linear-gradient(135deg, #8BC34A, #558B2F);
}

.summary-score.fair {
  background: linear-gradient(135deg, #FFC107, #FFA000);
}

.summary-score.poor {
  background: linear-gradient(135deg, #F44336, #C62828);
}

.score-value {
  display: block;
  font-size: 36px;
  font-weight: bold;
  color: white;
}

.score-label {
  display: block;
  font-size: 14px;
  color: rgba(255, 255, 255, 0.8);
  margin-top: 4px;
}

.summary-stats {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 8px;
}

.stat {
  background: #333;
  padding: 12px;
  border-radius: 6px;
  text-align: center;
}

.stat.passed { border-bottom: 3px solid #4CAF50; }
.stat.errors { border-bottom: 3px solid #F44336; }
.stat.warnings { border-bottom: 3px solid #FFC107; }
.stat.info { border-bottom: 3px solid #2196F3; }

.stat-count {
  display: block;
  font-size: 24px;
  font-weight: bold;
  color: #e0e0e0;
}

.stat-label {
  display: block;
  font-size: 12px;
  color: #999;
  margin-top: 4px;
}

/* Results */
.validation-results {
  margin-top: 16px;
}

.result-section {
  margin-bottom: 12px;
  border: 1px solid #333;
  border-radius: 6px;
  overflow: hidden;
}

.result-section.errors { border-color: #F44336; }
.result-section.warnings { border-color: #FFC107; }
.result-section.info { border-color: #2196F3; }
.result-section.passed { border-color: #4CAF50; }

.result-header {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 12px;
  background: #2a2a2a;
  cursor: pointer;
  user-select: none;
}

.result-header:hover {
  background: #333;
}

.expand-icon {
  font-size: 12px;
  color: #999;
}

.result-header h4 {
  margin: 0;
  font-size: 14px;
  font-weight: 600;
}

.result-items {
  background: #252525;
  padding: 8px;
}

.result-item {
  background: #2a2a2a;
  padding: 12px;
  border-radius: 4px;
  margin-bottom: 8px;
}

.result-item:last-child {
  margin-bottom: 0;
}

.result-item.passed {
  background: #1b331b;
  border-left: 3px solid #4CAF50;
}

.item-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 8px;
}

.item-name {
  font-weight: 600;
  color: #e0e0e0;
}

.item-rule {
  font-size: 12px;
  color: #666;
  background: #333;
  padding: 2px 6px;
  border-radius: 3px;
}

.item-details {
  font-size: 14px;
  color: #bbb;
  margin-bottom: 8px;
}

.item-suggestion {
  font-size: 13px;
  color: #4CAF50;
  background: rgba(76, 175, 80, 0.1);
  padding: 8px;
  border-radius: 4px;
}

.no-results {
  text-align: center;
  padding: 32px;
  color: #666;
}

.validator-footer {
  margin-top: 16px;
  padding-top: 16px;
  border-top: 1px solid #333;
  text-align: right;
}

.btn-export {
  background: #2196F3;
  color: white;
  border: none;
  padding: 8px 16px;
  border-radius: 4px;
  cursor: pointer;
  font-weight: 500;
  transition: background 0.2s;
}

.btn-export:hover {
  background: #1976D2;
}
</style>
