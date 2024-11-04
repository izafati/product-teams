# Background

1 year ago, a **[Salesforce experimentation](https://medium.com/@elhassak.m/salesforce-product-sharing-experimentation-48425ff411ae)** was done around Product sharing by **[Mustapha El Hassak](https://www.linkedin.com/in/elhassak/)**, **[Hamza Ait Bensaid](https://www.linkedin.com/in/hamzaaitbensaid/)**, **[Oumaima Arbani](https://www.linkedin.com/in/oarbani/)** and **[Zakaria Semri](https://www.linkedin.com/in/zakariasemri/)**. The conclusion was and is still the following:
* Products have limited sharing capabilities:
    * No sharing rules _(except Guest user sharing rules)_;
    * No manual sharing;
    * No owner field;
    * Only OWDs supported.
* A product creator cannot control who can edit or manage it, or limit its access to specific people.

_Fast forward to some months ago, and it turns out Zakaria couldn’t stop thinking about those limited sharing options!_

**Zakaria** called **[Tarik Ouhamou](https://www.linkedin.com/in/tarik-ouhamou-2528ab184/)** and **Imad Eddine Zafati** _(yes, no Linkedin...)_, to help him designing and building a solution inspired by the second point around giving the product creator more control. Which is somewhat similar to Account Teams for example, but with a lot of enhancements as the following chapters will describe.

# Solution Overview

* Custom Object for **Product Team Members**
    * This object keeps track of who on the team can view, edit, or have full access to each product.
    * A Product Team Member can be either a User, Role, Public Group, Queue, Territory or users with a specific Permission Set
    * For each Product, you can see all members’ access levels and the reasons behind them, calculated based on all types of members (like Role, Public Group, etc.).
* Product Object's **OWD** (Organization-Wide Default) Set to Public Read/Write
    * This setting gives everyone access, but their specific permissions are controlled through the Product Team Members object.
* Before Upsert **Trigger** on Product Object
    * This trigger checks a user’s access level (as defined in the Product Team Members object) before allowing them to make any edits.
* Before Upsert **Trigger** on Product Team Member Object
    * This trigger checks the access level (also defined in the Product Team Members object) before allowing a user to add, edit, or remove team members.
      
## Example
<img width="787" alt="image" src="https://github.com/user-attachments/assets/ff81f1ab-4c36-41f4-ae0f-ba7f16cff5b7">

_Note: Remember that the Product's OWDs are set to Public R/W, therefore all users will have implicit read access by default._

# Demo

#### Adding a product team member
In this example, we are adding a product team member. We choose the member type as User, search and choose Manal. Then, we select the product team member role, and finally the level of access.
![adding team member](https://github.com/user-attachments/assets/3e54aff5-fbdb-4eeb-9a0b-e48a8d0c9ed5)



#### Attempting to edit a product without the right access (edit or full access)
Oumaima, who has only read access on this product, is attempting to edit it. When trying to do so, she's getting an access error due to not having either Edit or Full Access.
![attempt to edit product without edit access](https://github.com/user-attachments/assets/f2b23982-1a80-499b-948c-28b664b4d59b)




#### Attempting to add a product team member without the full access
Manal has only Edit access to this product. If she tries adding a new product team member or editing an existing one, she will be prevented from doing so.
![attempt to add team member without full access](https://github.com/user-attachments/assets/6f70ec77-0cb4-49b1-9a41-4a007017ae7d)


#### View who has access by users, and with what level
In this example, the product has multiple members: Role, Permission Set and specific users. In order to get a detailed view on who has access by users, with what level and which reason, we can use the quick action Product Team Member Access.

Also, as you notice, Omar is a direct team member with only Read access. But since he has the role Rabat Marketing Agent assigned (The role itself is a member with full access), Omar will get the most permissive level of access which is Full Access.
![view access](https://github.com/user-attachments/assets/3d93a2b7-ab8d-499b-ad93-1f3543d2573f)


## "How to" guide
<img width="880" alt="image" src="https://github.com/user-attachments/assets/0498cd15-4563-4375-b5ca-ceb49a29c8dc">

## Data Model
<img width="383" alt="image" src="https://github.com/user-attachments/assets/a942c7ac-9c81-4bcc-a795-21781fcc7269">

# Process Flows
### Updating a Product
<img width="693" alt="image" src="https://github.com/user-attachments/assets/d39d3c94-1106-4a8f-819a-4595edda989d">

### Creating or Updating a Product Team Member
<img width="722" alt="image" src="https://github.com/user-attachments/assets/3d623464-7aa5-4216-b02b-3a9b12ebce12">

### Deleting a Product Team Member
<img width="713" alt="image" src="https://github.com/user-attachments/assets/30de0d23-2046-426b-8bf8-1ab42e0254a7">


# Limitations
* Nested groups & subordinates roles and territories are not supported. In other words, when adding groups, roles, territories and queues as members, only direct users under these are granted access.
    * Reason: Tables where all nested users are not visible. We can calculate them thanks to recursivity, however the performance can be an issue.
    * Workaround: Assign a permission set to these users, and add it as a member.

# Credits
This project uses the LWC Lookup component developed by pozil, available in the sfdc-ui-lookup-lwc  **[sfdc-ui-lookup-lwc repository](https://github.com/pozil/sfdc-ui-lookup-lwc)**. Special thanks to the author for making this component available as open source!

## License

This project is licensed under the MIT License.

```MIT License

Copyright (c) 2024 Imad Eddine ZAFATI & Tarik Ouhamou & Zakaria SEMRI

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.




