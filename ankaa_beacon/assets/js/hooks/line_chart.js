import Chart from "chart.js/auto";

const LineChart = {
  mounted() {
    this.chart = this.initChart();
  },

  updated() {
    if (this.chart) {
      this.chart.destroy();
    }
    this.chart = this.initChart();
  },

  destroyed() {
    if (this.chart) {
      this.chart.destroy();
    }
  },

  initChart() {
    const ctx = this.el;
    const data = JSON.parse(ctx.dataset.chartData);

    return new Chart(ctx, {
      type: "line",
      data: data,
      options: {
        responsive: true,
        maintainAspectRatio: false,
        interaction: {
          mode: "index",
          intersect: false,
        },
        plugins: {
          legend: {
            position: "top",
          },
          tooltip: {
            mode: "index",
            intersect: false,
          },
        },
        scales: {
          y: {
            beginAtZero: false,
            grid: {
              color: "rgba(0, 0, 0, 0.1)",
            },
          },
          x: {
            grid: {
              display: false,
            },
          },
        },
      },
    });
  },
};

export default LineChart;
