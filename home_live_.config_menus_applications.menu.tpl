<?xml version="1.0"?>
<!DOCTYPE Menu PUBLIC "-//freedesktop//DTD Menu 1.0//EN" "http://www.freedesktop.org/standards/menu-spec/1.0/menu.dtd">

<Menu>

  <Name>Applications</Name>

  <!-- Read .desktop files from only this location -->
  <AppDir>/usr/local/share/applications</AppDir>

  <!-- Define a layout -->
  <Layout>
          <Menuname>Office</Menuname>
          <Menuname>Internet</Menuname>
          <Menuname>Sound & Video</Menuname>
          <Menuname>Graphics</Menuname>
          <Menuname>Accessories</Menuname>
  </Layout>

  <!-- Office submenu -->
  <Menu>
    <Name>Office</Name>
    <Include> <Category>Office</Category> </Include>
  </Menu>
  
  <!-- Sound & Video submenu -->
  <Menu>
    <Name>Sound & Video</Name>
    <Include> <Category>AudioVideo</Category> </Include>
  </Menu>

  <!-- Internet submenu -->
  <Menu>
    <Name>Internet</Name>
    <Include> <Category>Network</Category> </Include>
  </Menu>

  <!-- Graphics submenu -->
  <Menu>
    <Name>Graphics</Name>
    <Include> <Category>Graphics</Category> </Include>
  </Menu>

  <!-- Accessories submenu -->
  <Menu>
    <Name>Accessories</Name>
    <Include> <Category>Console</Category> </Include>
  </Menu>

</Menu>
