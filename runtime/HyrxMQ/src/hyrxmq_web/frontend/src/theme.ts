import { createTheme } from "@mui/material/styles";

const theme = createTheme({
  palette: {
    mode: "dark",
    primary: { main: "#64a6f7", contrastText: "#020a13" },
    secondary: { main: "#084386", contrastText: "#ffffff" },
    background: {
      default: "#020a13",
      paper: "#0b4587",
    },
    text: {
      primary: "#ffffff",
      secondary: "rgba(255,255,255,0.7)",
    },
    success: { main: "#76ff03" },
    error: { main: "#ff1744" },
    warning: { main: "#ffab00" },
    info: { main: "#64a6f7" },
  },
  typography: {
    fontFamily: '"Inter", "Roboto", "Helvetica", "Arial", sans-serif',
    h4: { fontWeight: 700 },
    h6: { fontWeight: 600 },
  },
  shape: { borderRadius: 2 },
  components: {
    MuiCard: {
      styleOverrides: {
        root: {
          backgroundImage: "none",
          backgroundColor: "rgba(8, 67, 134, 0.4)",
          backdropFilter: "blur(8px)",
          border: "1px solid rgba(100, 166, 247, 0.15)",
          borderRadius: 2,
        },
      },
    },
    MuiPaper: {
      styleOverrides: {
        root: { backgroundImage: "none" },
      },
    },
    MuiAppBar: {
      styleOverrides: {
        root: {
          backgroundImage: "none",
        },
      },
    },
    MuiChip: {
      styleOverrides: {
        root: {
          fontWeight: 600,
        },
      },
    },
  },
});

export default theme;
